#import "Foundation/Foundation.h"
#import "../Macros.h"
#import <vector>

#define OFFSET_fieldOfView 0x40
#define OFFSET_jumpHeight 0x4C

// Store value
std::vector<void *> instanceGamePlayCameraConfig;
std::vector<void *> instanceCharacterMotorConfig;
std::map<void *, float> fieldOfViewOrgs;
std::map<void *, float> jumpHeightOrgs;
float fieldOfView = 1.0;
float jumpHeight = 1.0;

// ================================================================================== //

void (*_SYBO_Subway_GameplayCameraConfig___ctor)(
                                                 void *self,
                                                 void *method);
void SYBO_Subway_GameplayCameraConfig___ctor(
                                             void *self,
                                             void *method) {
    _SYBO_Subway_GameplayCameraConfig___ctor(self, method);
    
    instanceGamePlayCameraConfig.push_back(self);
    float fieldOfViewOrg = *(float *)((uintptr_t)self + OFFSET_fieldOfView);
    fieldOfViewOrgs.insert({self, fieldOfViewOrg});
}

void (*_SYBO_RunnerCore_Character_CharacterMotorConfig___ctor)(
                                                               void *self,
                                                               void *method);
void SYBO_RunnerCore_Character_CharacterMotorConfig___ctor(
                                                           void *self,
                                                           void *method){
    _SYBO_RunnerCore_Character_CharacterMotorConfig___ctor(self, method);
    
    instanceCharacterMotorConfig.push_back(self);
    float jumpHeightOrg = *(float *)((uintptr_t)self + OFFSET_jumpHeight);
    jumpHeightOrgs.insert({self, jumpHeightOrg});
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
        float fieldOfViewOrg = fieldOfViewOrgs[instance];
        *(float *)((uintptr_t)instance + OFFSET_fieldOfView) = fieldOfViewOrg * fieldOfView;
    }
    
    index = 0;
    for (void *instance: instanceCharacterMotorConfig) {
        ++index;
        if (!instance) {
            instanceCharacterMotorConfig.erase(instanceCharacterMotorConfig.begin() + index);
            jumpHeightOrgs.erase(instance);
            continue;
        }
        float jumpHeightOrg = jumpHeightOrgs[instance];
        *(float *)((uintptr_t)instance + OFFSET_jumpHeight) = jumpHeightOrg * jumpHeight;
    }
}
