#import "Foundation/Foundation.h"
#import "../Macros.h"
#import <vector>

// Store value
std::vector<void *> instanceGamePlayCameraConfig;
std::map<void *, float> fieldOfViewOrgs;
float fieldOfView = 1.0;

// ================================================================================== //

void (*_SYBO_Subway_GameplayCameraConfig___ctor)(
                                                 void *self,
                                                 void *method);
void SYBO_Subway_GameplayCameraConfig___ctor(
                                             void *self,
                                             void *method) {
    _SYBO_Subway_GameplayCameraConfig___ctor(self, method);
    
    instanceGamePlayCameraConfig.push_back(self);
    float fieldOfViewOrg = *(float *)((uintptr_t)self + 0x40);
    fieldOfViewOrgs.insert({self, fieldOfViewOrg});
}

void applyMod() {
    for (void *instance: instanceGamePlayCameraConfig) {
        if (!instance) {
            fieldOfViewOrgs.erase(instance);
            continue;
        }
        float fieldOfViewOrg = fieldOfViewOrgs[instance];
        *(float *)((uintptr_t)instance + 0x40) = fieldOfViewOrg * fieldOfView;
    }
}
