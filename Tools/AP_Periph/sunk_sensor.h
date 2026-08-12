#pragma once

#if AP_PERIPH_SUNK_SENSOR_ENABLED

class SunkSensor {
public:
    void init(void);
    void update(void);
};

#endif // AP_PERIPH_SUNK_SENSOR_ENABLED