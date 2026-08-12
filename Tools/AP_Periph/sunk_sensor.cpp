#include "AP_Periph.h"

#if AP_PERIPH_SUNK_SENSOR_ENABLED

#include <dronecan_msgs.h>

extern const AP_HAL::HAL &hal;

uint8_t buffer[1];

void SunkSensor::init(void){
    //keep empty for now
    hal.gpio->pinMode(HAL_GPIO_SUNK_SENSOR_OUTPUT, HAL_GPIO_OUTPUT);
    hal.gpio->pinMode(HAL_GPIO_SUNK_SENSOR_INPUT, HAL_GPIO_INPUT);

    hal.gpio->write(HAL_GPIO_SUNK_SENSOR_OUTPUT, 0);
    hal.gpio->write(HAL_GPIO_SUNK_SENSOR_INPUT, 1); //enable with pullup

} 

void SunkSensor::update(void)
{
    hal.gpio->toggle(HAL_GPIO_SUNK_SENSOR_OUTPUT);

    bool sunk = false;
    if(hal.gpio->read(HAL_GPIO_SUNK_SENSOR_INPUT)){
        sunk = true;
    }

    if(sunk){
        buffer[0] = SUNFISH_INDICATION_SUNKSTATE_STATUS_SUNK;
        periph.canard_broadcast(SUNFISH_INDICATION_SUNKSTATE_SIGNATURE,
            SUNFISH_INDICATION_SUNKSTATE_ID,
            CANARD_TRANSFER_PRIORITY_LOW,
            &buffer[0],
            SUNFISH_INDICATION_SUNKSTATE_MAX_SIZE);
    }else{
        buffer[0] = SUNFISH_INDICATION_SUNKSTATE_STATUS_NOT_SUNK;
        periph.canard_broadcast(SUNFISH_INDICATION_SUNKSTATE_SIGNATURE,
            SUNFISH_INDICATION_SUNKSTATE_ID,
            CANARD_TRANSFER_PRIORITY_LOW,
            &buffer[0],
            SUNFISH_INDICATION_SUNKSTATE_MAX_SIZE);
    }
}

#endif // AP_PERIPH_SUNK_SENSOR_ENABLED