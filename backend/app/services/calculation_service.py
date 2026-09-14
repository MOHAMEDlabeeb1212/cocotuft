# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - CALCULATION SERVICE
# ==============================================================================
# Section Purpose: Authoritative server-side calculation engine for Tufting production:
# 1. Actual Qty (SQM) = Length (m) x Width (m)
# 2. Variation = Actual Qty - Target Qty
# 3. Balance Qty = Target Qty - Actual Qty
# 4. Total Running Meter = Sum of Lengths
# ==============================================================================

class CalculationService:
    """
    Business calculation service for Daily Tufting Details & Production Summary.
    """

    @staticmethod
    def compute_tufting_metrics(length_meters: float, width_meters: float, target_qty: float) -> dict:
        """
        Calculates Actual Qty (SQM), Variation, Balance Qty, and Running Meter.
        """
        if length_meters < 0 or width_meters < 0 or target_qty < 0:
            raise ValueError("Length, Width, and Target Qty must be non-negative.")

        actual_qty = round(length_meters * width_meters, 2)
        variation = round(actual_qty - target_qty, 2)
        balance_qty = round(target_qty - actual_qty, 2)
        running_meter = round(length_meters, 2)

        return {
            "actual_qty": actual_qty,
            "variation": variation,
            "balance_qty": balance_qty,
            "running_meter": running_meter,
        }
