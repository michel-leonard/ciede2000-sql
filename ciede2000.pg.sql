-- This function written in SQL is not affiliated with the CIE (International Commission on Illumination),
-- and is released into the public domain. It is provided "as is" without any warranty, express or implied.

-- Convenience function, with parametric factors set to their default values.
CREATE OR REPLACE FUNCTION ciede2000(
  l1 DOUBLE PRECISION,
  a1 DOUBLE PRECISION,
  b1 DOUBLE PRECISION,
  l2 DOUBLE PRECISION,
  a2 DOUBLE PRECISION,
  b2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
STRICT
PARALLEL SAFE
AS $$
BEGIN
	RETURN ciede2000_with_parameters(l1, a1, b1, l2, a2, b2, 1.0, 1.0, 1.0, FALSE);
END;
$$;

-- The classic CIE ΔE2000 implementation, which operates on two L*a*b* colors, and returns their difference.
-- "l" ranges from 0 to 100, while "a" and "b" are unbounded and commonly clamped to the range of -128 to 127.
CREATE OR REPLACE FUNCTION ciede2000_with_parameters(
  l1 DOUBLE PRECISION,
  a1 DOUBLE PRECISION,
  b1 DOUBLE PRECISION,
  l2 DOUBLE PRECISION,
  a2 DOUBLE PRECISION,
  b2 DOUBLE PRECISION,
  kl DOUBLE PRECISION,
  kc DOUBLE PRECISION,
  kh DOUBLE PRECISION,
  canonical BOOLEAN
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
STRICT
PARALLEL SAFE
AS $$
DECLARE
n DOUBLE PRECISION;
c1 DOUBLE PRECISION;
c2 DOUBLE PRECISION;
h1 DOUBLE PRECISION;
h2 DOUBLE PRECISION;
h_mean DOUBLE PRECISION;
h_delta DOUBLE PRECISION;
r_t DOUBLE PRECISION;
p DOUBLE PRECISION;
t DOUBLE PRECISION;
l DOUBLE PRECISION;
c DOUBLE PRECISION;
h DOUBLE PRECISION;
BEGIN
	n := (SQRT(a1 * a1 + b1 * b1) + SQRT(a2 * a2 + b2 * b2)) * 0.5;
	n := n * n * n * n * n * n * n;
	-- A factor involving chroma raised to the power of 7 designed to make
	-- the influence of chroma on the total color difference more accurate.
	n := 1.0 + 0.5 * (1.0 - SQRT(n / (n + 6103515625.0)));
	-- Application of the chroma correction factor.
	c1 := SQRT(a1 * a1 * n * n + b1 * b1);
	c2 := SQRT(a2 * a2 * n * n + b2 * b2);
	-- atan2 is preferred over atan because it accurately computes the angle of
	-- a point (x, y) in all quadrants, handling the signs of both coordinates.
	h1 := COALESCE(ATAN2(b1, a1 * n), 0);
	h2 := COALESCE(ATAN2(b2, a2 * n), 0);
	IF h1 < 0 THEN h1 := h1 + 2 * PI(); END IF;
	IF h2 < 0 THEN h2 := h2 + 2 * PI(); END IF;
	-- When the hue angles lie in different quadrants, the straightforward
	-- average can produce a mean that incorrectly suggests a hue angle in
	-- the wrong quadrant, the next lines handle this issue.
	h_mean := (h1 + h2) * 0.5;
	h_delta := (h2 - h1) * 0.5;
	-- The part where most programmers get it wrong.
	IF PI() + 1E-14 < ABS(h2 - h1) THEN
		h_delta := h_delta + PI();
		IF canonical AND PI() + 1E-14 < h_mean THEN
			-- Sharma’s implementation, OpenJDK, ...
			h_mean := h_mean - PI();
		ELSE
			-- Lindbloom’s implementation, Netflix’s VMAF, ...
			h_mean := h_mean + PI();
		END IF;
	END IF;
	p := 36.0 * h_mean - 55.0 * PI();
	n := (c1 + c2) * 0.5;
	n := n * n * n * n * n * n * n;
	-- The hue rotation correction term is designed to account for the
	-- non-linear behavior of hue differences in the blue region.
	r_t := -2.0 * SQRT(n / (n + 6103515625.0))
				* SIN(PI() / 3.0 * EXP(p * p / (-25.0 * PI() * PI())));
	n := (l1 + l2) * 0.5;
	n := (n - 50.0) * (n - 50.0);
	-- Lightness.
	l := (l2 - l1) / (kl * (1.0 + 0.015 * n / SQRT(20.0 + n)));
	-- These coefficients adjust the impact of different harmonic
	-- components on the hue difference calculation.
	t := 1.0	- 0.17 * SIN(h_mean + PI() / 3.0)
				+ 0.24 * SIN(2.0 * h_mean + PI() * 0.5)
				+ 0.32 * SIN(3.0 * h_mean + 8.0 * PI() / 15.0)
				- 0.20 * SIN(4.0 * h_mean + 3.0 * PI() / 20.0);
	n := c1 + c2;
	-- Hue.
	h := 2.0 * SQRT(c1 * c2) * SIN(h_delta) / (kh * (1.0 + 0.0075 * n * t));
	-- Chroma.
	c := (c2 - c1) / (kc * (1.0 + 0.0225 * n));
	-- The result reflects the actual geometric distance in color space, given a tolerance of 3.6e-13.
	RETURN SQRT(l * l + h * h + c * c + c * h * r_t);
END;
$$;

-- If you remove the constant 1E-14, the code will continue to work, but CIEDE2000
-- interoperability between all programming languages will no longer be guaranteed.

-- Source code tested by Michel LEONARD
-- Website: ciede2000.pages-perso.free.fr
