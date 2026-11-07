-- This function written in SQL is not affiliated with the CIE (International Commission on Illumination),
-- and is released into the public domain. It is provided "as is" without any warranty, express or implied.

DELIMITER //

-- Delete any function of the same name that already exists
DROP FUNCTION IF EXISTS ciede2000 //
DROP FUNCTION IF EXISTS ciede2000_with_parameters //

-- Convenience function, with parametric factors set to their default values.
CREATE FUNCTION ciede2000(l1 DOUBLE, a1 DOUBLE, b1 DOUBLE, l2 DOUBLE, a2 DOUBLE, b2 DOUBLE)
RETURNS DOUBLE
DETERMINISTIC
NO SQL
BEGIN
	RETURN ciede2000_with_parameters(l1, a1, b1, l2, a2, b2, 1.0, 1.0, 1.0, FALSE);
END //

-- The classic CIE ΔE2000 implementation, which operates on two L*a*b* colors, and returns their difference.
-- "l" ranges from 0 to 100, while "a" and "b" are unbounded and commonly clamped to the range of -128 to 127.
CREATE FUNCTION ciede2000_with_parameters(l1 DOUBLE, a1 DOUBLE, b1 DOUBLE, l2 DOUBLE, a2 DOUBLE, b2 DOUBLE, kl DOUBLE, kc DOUBLE, kh DOUBLE, canonical BOOLEAN)
RETURNS DOUBLE
DETERMINISTIC
NO SQL
BEGIN
	-- Working in SQL/PSM with the CIEDE2000 color-difference formula.
	-- kl, kc, kh are parametric factors to be adjusted according to
	-- different viewing parameters such as textures, backgrounds...
	DECLARE n, c1, c2, h1, h2, h_mean, h_delta, r_t, p, t, l, c, h DOUBLE;
	SET n = (SQRT(a1 * a1 + b1 * b1) + SQRT(a2 * a2 + b2 * b2)) * 0.5;
	SET n = n * n * n * n * n * n * n;
	-- A factor involving chroma raised to the power of 7 designed to make
	-- the influence of chroma on the total color difference more accurate.
	SET n = 1.0 + 0.5 * (1.0 - SQRT(n / (n + 6103515625.0)));
	-- Application of the chroma correction factor.
	SET c1 = SQRT(a1 * a1 * n * n + b1 * b1);
	SET c2 = SQRT(a2 * a2 * n * n + b2 * b2);
	-- atan2 is preferred over atan because it accurately computes the angle of
	-- a point (x, y) in all quadrants, handling the signs of both coordinates.
	SET h1 = COALESCE(ATAN2(b1, a1 * n), 0);
	SET h2 = COALESCE(ATAN2(b2, a2 * n), 0);
	IF h1 < 0 THEN SET h1 = h1 + 2 * PI(); END IF;
	IF h2 < 0 THEN SET h2 = h2 + 2 * PI(); END IF;
	-- When the hue angles lie in different quadrants, the straightforward
	-- average can produce a mean that incorrectly suggests a hue angle in
	-- the wrong quadrant, the next lines handle this issue.
	SET h_mean = (h1 + h2) * 0.5;
	SET h_delta = (h2 - h1) * 0.5;
	-- The part where most programmers get it wrong.
	IF PI() + 1E-14 < ABS(h2 - h1) THEN
		SET h_delta = h_delta + PI();
		IF canonical AND PI() + 1E-14 < h_mean THEN
			-- Sharma’s implementation, OpenJDK, ...
			SET h_mean = h_mean - PI();
		ELSE
			-- Lindbloom’s implementation, Netflix’s VMAF, ...
			SET h_mean = h_mean + PI();
		END IF;
	END IF;
	SET p = 36.0 * h_mean - 55.0 * PI();
	SET n = (c1 + c2) * 0.5;
	SET n = n * n * n * n * n * n * n;
	-- The hue rotation correction term is designed to account for the
	-- non-linear behavior of hue differences in the blue region.
	SET r_t = -2.0 * SQRT(n / (n + 6103515625.0))
				* SIN(PI() / 3.0 * EXP(p * p / (-25.0 * PI() * PI())));
	SET n = (l1 + l2) * 0.5;
	SET n = (n - 50.0) * (n - 50.0);
	-- Lightness.
	SET l = (l2 - l1) / (kl * (1.0 + 0.015 * n / SQRT(20.0 + n)));
	-- These coefficients adjust the impact of different harmonic
	-- components on the hue difference calculation.
	SET t = 1.0	- 0.17 * SIN(h_mean + PI() / 3.0)
				+ 0.24 * SIN(2.0 * h_mean + PI() * 0.5)
				+ 0.32 * SIN(3.0 * h_mean + 8.0 * PI() / 15.0)
				- 0.20 * SIN(4.0 * h_mean + 3.0 * PI() / 20.0);
	SET n = c1 + c2;
	-- Hue.
	SET h = 2.0 * SQRT(c1 * c2) * SIN(h_delta) / (kh * (1.0 + 0.0075 * n * t));
	-- Chroma.
	SET c = (c2 - c1) / (kc * (1.0 + 0.0225 * n));
	-- The result reflects the actual geometric distance in color space, given a tolerance of 3.6e-13.
	RETURN SQRT(l * l + h * h + c * c + c * h * r_t);
END //

DELIMITER ;

-- If you remove the constant 1E-14, the code will continue to work, but CIEDE2000
-- interoperability between all programming languages will no longer be guaranteed.

-- Source code tested by Michel LEONARD
-- Website: ciede2000.pages-perso.free.fr
