package com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils;

import java.security.SecureRandom;

public class NanoIdGenerator {

    private static final String DEFAULT_ALPHABET = "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private static final SecureRandom RANDOM = new SecureRandom();

    public static String generate(String prefix) {
        return prefix + randomNanoId(DEFAULT_ALPHABET, 21);
    }
    // Comment: Custom alphabet and length generator
    public static String randomNanoId(String alphabet, int size) {
        StringBuilder builder = new StringBuilder(size);
        for (int i = 0; i < size; i++) {
            int randomIndex = RANDOM.nextInt(alphabet.length());
            builder.append(alphabet.charAt(randomIndex));
        }
        return "zp_" + builder.toString();
    }
}