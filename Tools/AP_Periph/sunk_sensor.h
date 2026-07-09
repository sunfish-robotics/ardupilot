#pragma once

#if AP_PERIPH_SUNK_SENSOR_ENABLED

class SunkSensor {
public:
    void init(void);
    void update(void);

    uint32_t last_update_ms;
};

#endif // AP_PERIPH_SUNK_SENSOR_ENABLED