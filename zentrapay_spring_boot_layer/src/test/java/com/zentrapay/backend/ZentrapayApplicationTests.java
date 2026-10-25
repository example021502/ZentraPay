package com.zentrapay.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

// All required properties (JWT, peppers, gateway keys) come from src/test/resources/application.properties.
@SpringBootTest(classes = ZentrapayApplication.class)
class ZentrapayApplicationTests {

	@Test
	void contextLoads() {
	}
}