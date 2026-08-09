package com.zentrapay_application.zentrapay_spring_boot_layer;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

// All required properties (JWT, peppers, gateway keys) come from src/test/resources/application.properties.
@SpringBootTest(classes = ZentrapaySpringBootLayerApplication.class)
class ZentrapaySpringBootLayerApplicationTests {

	@Test
	void contextLoads() {
	}
}