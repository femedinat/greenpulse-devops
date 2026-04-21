package com.greenpulse;

import java.time.OffsetDateTime;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/")
    public Map<String, Object> home() {
        return Map.of(
                "project", "Cidades ESGInteligentes",
                "application", "GreenPulse",
                "description", "Monitoramento inteligente de consumo de energia (ESG)",
                "status", "running",
                "timestamp", OffsetDateTime.now().toString()
        );
    }

    @GetMapping("/api/energy/status")
    public Map<String, Object> energyStatus() {
        return Map.of(
                "currentConsumptionKwh", 128.4,
                "efficiencyScore", 91,
                "alertLevel", "normal",
                "source", "simulated-iot-sensors"
        );
    }
}
