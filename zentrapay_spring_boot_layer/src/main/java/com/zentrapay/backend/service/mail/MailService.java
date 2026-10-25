package com.zentrapay.backend.service.mail;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Sends plain-text emails. SMTP is configured with the usual {@code spring.mail.*} properties (see
 * application.properties); when no SMTP host is set there is no mail sender and {@link #send} reports
 * that nothing was sent, so the caller can tell the user instead of pretending an email went out.
 */
@Slf4j
@Service
public class MailService {

    private final ObjectProvider<JavaMailSender> mailSender;
    private final String from;

    public MailService(ObjectProvider<JavaMailSender> mailSender,
                       @Value("${app.mail.from:no-reply@zentrapay.com}") String from) {
        this.mailSender = mailSender;
        this.from = from;
    }

    /** True when an SMTP server is configured. */
    public boolean isConfigured() {
        return mailSender.getIfAvailable() != null;
    }

    /**
     * Sends the email. Returns false (and logs why) when mail is not configured or the server refused it.
     * The body is never logged: it can hold one-time codes.
     */
    public boolean send(String to, String subject, String body) {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender == null) {
            log.warn("Email '{}' to {} NOT sent: no SMTP server is configured (set spring.mail.host)", subject, to);
            return false;
        }
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(from);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);
            sender.send(message);
            log.info("Email '{}' sent to {}", subject, to);
            return true;
        } catch (Exception e) {
            log.error("Email '{}' to {} failed: {}", subject, to, e.getMessage());
            return false;
        }
    }
}
