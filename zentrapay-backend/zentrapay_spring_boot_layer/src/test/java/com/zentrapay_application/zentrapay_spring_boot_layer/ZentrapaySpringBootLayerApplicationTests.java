package com.zentrapay_application.zentrapay_spring_boot_layer;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest(classes = ZentrapaySpringBootLayerApplication.class)
@TestPropertySource(properties = {
		"app.jwt.jwt_secret_key=91902318b8c1a3fbd698e4d17ce0d99f386d9b2de947796f47d72bc2fd81146b",
		"app.internal.header_name=X-Internal-Secret",
		"app.internal.secret_key=50d17c8eae583122dfd0e9a2986621343152f4a51c39798b81a4b8164d2b30d4",
		"app.password.pepper=zentrapay@123password_application",
		"app.pin.pepper=zentrapay@pin_application"
})
class ZentrapaySpringBootLayerApplicationTests {

	@Test
	void contextLoads() {
	}
}