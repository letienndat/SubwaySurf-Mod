#import "Foundation/Foundation.h"
#import "../Macros.h"
#import <vector>

#define OFFSET_fieldOfView 0x40
#define OFFSET_jumpHeight 0x4C
#define OFFSET_initialTargetSpeed 0x24

// Store value
std::vector<void *> instanceGamePlayCameraConfig;
std::vector<void *> instanceCharacterMotorConfig;
std::map<void *, float> fieldOfViewOrgs;
std::map<void *, float> jumpHeightOrgs;
std::map<void *, float> initialTargetSpeedOrgs;
float fieldOfViewScale = 1.0;
float jumpHeightScale = 1.0;
float initialTargetSpeedScale = 1.0;
bool isChangeFieldOfViewScale = false;
bool isChangeJumpHeightScale = false;
bool isChangeInitialTargetSpeedScale = false;

// ================================================================================== //

void (*_SYBO_Subway_GameplayCameraConfig___ctor)(void *self, void *method);
void SYBO_Subway_GameplayCameraConfig___ctor( void *self, void *method) {
    _SYBO_Subway_GameplayCameraConfig___ctor(self, method);
    instanceGamePlayCameraConfig.push_back(self);
}

void (*_SYBO_RunnerCore_Character_CharacterMotorConfig___ctor)(void *self, void *method);
void SYBO_RunnerCore_Character_CharacterMotorConfig___ctor(void *self, void *method){
    _SYBO_RunnerCore_Character_CharacterMotorConfig___ctor(self, method);
    instanceCharacterMotorConfig.push_back(self);
}

void applyMod() {
    uint32_t index = 0;
    for (void *instance: instanceGamePlayCameraConfig) {
        ++index;
        if (!instance) {
            instanceGamePlayCameraConfig.erase(instanceGamePlayCameraConfig.begin() + index);
            fieldOfViewOrgs.erase(instance);
            continue;
        }
        if (!isChangeFieldOfViewScale) {
            float fieldOfViewOrg = *(float *)((uintptr_t)instance + OFFSET_fieldOfView);
            fieldOfViewOrgs.insert({instance, fieldOfViewOrg});
            continue;
        }
        float fieldOfViewOrg = fieldOfViewOrgs[instance];
        *(float *)((uintptr_t)instance + OFFSET_fieldOfView) = fieldOfViewOrg * fieldOfViewScale;
    }
    
    index = 0;
    for (void *instance: instanceCharacterMotorConfig) {
        ++index;
        if (!instance) {
            instanceCharacterMotorConfig.erase(instanceCharacterMotorConfig.begin() + index);
            jumpHeightOrgs.erase(instance);
            initialTargetSpeedOrgs.erase(instance);
            continue;
        }
        if (!isChangeJumpHeightScale) {
            float jumpHeightOrg = *(float *)((uintptr_t)instance + OFFSET_jumpHeight);
            jumpHeightOrgs.insert({instance, jumpHeightOrg});
        } else {
            float jumpHeightOrg = jumpHeightOrgs[instance];
            *(float *)((uintptr_t)instance + OFFSET_jumpHeight) = jumpHeightOrg * jumpHeightScale;
        }
        
        if (!isChangeInitialTargetSpeedScale) {
            float initialTargetSpeedOrg = *(float *)((uintptr_t)instance + OFFSET_initialTargetSpeed);
            initialTargetSpeedOrgs.insert({instance, initialTargetSpeedOrg});
            continue;
        }
        float initialTargetSpeedOrg = initialTargetSpeedOrgs[instance];
        *(float *)((uintptr_t)instance + OFFSET_initialTargetSpeed) = initialTargetSpeedOrg * initialTargetSpeedScale;
    }
}
