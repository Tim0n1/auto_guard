import math


class Solution(object):
    def angleClock(self, hour, minutes):
        """
        :type hour: int
        :type minutes: int
        :rtype: float
        """
        hour_degree = 30
        minute_degree = 6
        if hour == 12:
            hour = 0
        minute_angle = minutes * minute_degree
        hour_angle = hour * hour_degree + hour_degree * (minutes / 60)
        angle = abs(hour_angle - minute_angle)
        if angle > 180:
            angle = 180 - angle
        return angle
sol = Solution()
print(sol.angleClock(3,15))
