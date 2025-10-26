package com.example.investmentdatastreamservice.utils;

import java.math.BigDecimal;
import java.math.RoundingMode;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import ru.tinkoff.piapi.contract.v1.Quotation;

/**
 * Утилитный класс для работы с Quotation из T-Invest API
 * 
 * Предоставляет методы для преобразования Quotation в BigDecimal
 * с правильной обработкой целой и дробной частей.
 */
public class QuotationUtils {

    private static final Logger logger = LoggerFactory.getLogger(QuotationUtils.class);

    /**
     * Преобразование Quotation в BigDecimal
     * 
     * Quotation содержит:
     * - units: целая часть числа (int64)
     * - nano: дробная часть в наносекундах (int32, 0-999,999,999)
     * 
     * @param quotation объект Quotation из T-Invest API
     * @return BigDecimal значение или BigDecimal.ZERO если quotation null
     */
    public static BigDecimal toBigDecimal(Quotation quotation) {
        if (quotation == null) {
            logger.debug("Quotation is null, returning BigDecimal.ZERO");
            return BigDecimal.ZERO;
        }
        
        try {
            // Преобразуем units (целая часть) в BigDecimal
            BigDecimal units = BigDecimal.valueOf(quotation.getUnits());
            
            // Преобразуем nano (дробная часть) в BigDecimal
            // nano представляет наносекунды, нужно разделить на 10^9
            BigDecimal nano = BigDecimal.valueOf(quotation.getNano()).movePointLeft(9);
            
            // Суммируем целую и дробную части
            BigDecimal result = units.add(nano);
            
            if (logger.isDebugEnabled()) {
                logger.debug("Converted Quotation: units={}, nano={}, result={}", 
                        quotation.getUnits(), quotation.getNano(), result);
            }
            
            return result;
        } catch (Exception e) {
            logger.error("Ошибка при преобразовании Quotation в BigDecimal: {}", e.getMessage(), e);
            return BigDecimal.ZERO;
        }
    }

    /**
     * Преобразование Quotation в BigDecimal с указанием масштаба
     * 
     * @param quotation объект Quotation из T-Invest API
     * @param scale количество знаков после запятой
     * @return BigDecimal значение с указанным масштабом
     */
    public static BigDecimal toBigDecimal(Quotation quotation, int scale) {
        BigDecimal result = toBigDecimal(quotation);
        return result.setScale(scale, RoundingMode.HALF_UP);
    }

    /**
     * Проверка, является ли Quotation нулевым
     * 
     * @param quotation объект Quotation
     * @return true если quotation null или равен нулю
     */
    public static boolean isZero(Quotation quotation) {
        if (quotation == null) {
            return true;
        }
        return quotation.getUnits() == 0 && quotation.getNano() == 0;
    }

    /**
     * Проверка, является ли Quotation положительным
     * 
     * @param quotation объект Quotation
     * @return true если quotation положительный
     */
    public static boolean isPositive(Quotation quotation) {
        if (quotation == null) {
            return false;
        }
        return quotation.getUnits() > 0 || (quotation.getUnits() == 0 && quotation.getNano() > 0);
    }

    /**
     * Проверка, является ли Quotation отрицательным
     * 
     * @param quotation объект Quotation
     * @return true если quotation отрицательный
     */
    public static boolean isNegative(Quotation quotation) {
        if (quotation == null) {
            return false;
        }
        return quotation.getUnits() < 0 || (quotation.getUnits() == 0 && quotation.getNano() < 0);
    }

    /**
     * Сравнение двух Quotation
     * 
     * @param q1 первое Quotation
     * @param q2 второе Quotation
     * @return -1 если q1 < q2, 0 если q1 == q2, 1 если q1 > q2
     */
    public static int compare(Quotation q1, Quotation q2) {
        if (q1 == null && q2 == null) {
            return 0;
        }
        if (q1 == null) {
            return -1;
        }
        if (q2 == null) {
            return 1;
        }
        
        BigDecimal bd1 = toBigDecimal(q1);
        BigDecimal bd2 = toBigDecimal(q2);
        
        return bd1.compareTo(bd2);
    }

    /**
     * Создание Quotation из BigDecimal
     * 
     * @param value BigDecimal значение
     * @return Quotation объект
     */
    public static Quotation fromBigDecimal(BigDecimal value) {
        if (value == null) {
            return Quotation.newBuilder()
                    .setUnits(0)
                    .setNano(0)
                    .build();
        }
        
        try {
            // Получаем целую часть
            long units = value.longValue();
            
            // Получаем дробную часть (умножаем на 10^9 и берем остаток)
            BigDecimal fractionalPart = value.subtract(BigDecimal.valueOf(units));
            int nano = fractionalPart.multiply(BigDecimal.valueOf(1_000_000_000)).intValue();
            
            return Quotation.newBuilder()
                    .setUnits(units)
                    .setNano(nano)
                    .build();
        } catch (Exception e) {
            logger.error("Ошибка при преобразовании BigDecimal в Quotation: {}", e.getMessage(), e);
            return Quotation.newBuilder()
                    .setUnits(0)
                    .setNano(0)
                    .build();
        }
    }

    /**
     * Строковое представление Quotation для отладки
     * 
     * @param quotation объект Quotation
     * @return строковое представление
     */
    public static String toString(Quotation quotation) {
        if (quotation == null) {
            return "Quotation{null}";
        }
        return String.format("Quotation{units=%d, nano=%d, value=%s}", 
                quotation.getUnits(), 
                quotation.getNano(), 
                toBigDecimal(quotation));
    }
}
