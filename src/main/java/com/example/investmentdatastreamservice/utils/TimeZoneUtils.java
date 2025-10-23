package com.example.investmentdatastreamservice.utils;
import java.time.ZoneId;


public class TimeZoneUtils {
    /**
     * Константа для московской временной зоны (UTC+3)
     */
    public static final ZoneId MOSCOW_ZONE = ZoneId.of("Europe/Moscow");
    
    /**
     * Получить московскую временную зону
     * @return ZoneId для Europe/Moscow
     */
    public static ZoneId getMoscowZone() {
        return MOSCOW_ZONE;
    }

}
