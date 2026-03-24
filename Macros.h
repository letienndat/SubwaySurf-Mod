//
//  Macros.h
//  ModMenu
//
//  Created by Joey on 4/2/19.
//  Copyright © 2019 Joey. All rights reserved.
//

#import "Obfuscate.h"
#import "Foundation/Foundation.h"
#import "Common.h"
#import "KittyMemory/MemoryPatch.hpp"
#import "KittyMemory/writeData.hpp"
#import "KittyMemory/KittyUtils.hpp"
#import "giovotinh/patch.h"
#import "giovotinh/il2cpp.h"

#include <substrate.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

#define LOG(...) \
  NSLog(@"%@ %@", NSSENCRYPT("Tweak Mod >>>"), [NSString stringWithFormat:__VA_ARGS__])

// thanks to shmoo for the usefull stuff under this comment.
#define timer(sec) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC), dispatch_get_main_queue(), ^
#define onMain(block) dispatch_async(dispatch_get_main_queue(), block)
#define HOOK(offset, ptr, orig) MSHookFunction((void *)getRealOffset(offset), (void *)ptr, (void **)&orig)
#define HOOK_NO_ORIG(offset, ptr) MSHookFunction((void *)getRealOffset(offset), (void *)ptr, NULL)
#define HOOK_V2(offset, ptr, orig)                               \
  NSString *result_##ptr = StaticInlineHookPatch(                \
      (char *)[common getFrameworkName], offset, nullptr);       \
  if (result_##ptr)                                              \
  {                                                              \
    LOG(@"Hook result: %s", result_##ptr.UTF8String);            \
    void *result = StaticInlineHookFunction(                     \
        (char *)[common getFrameworkName], offset, (void *)ptr); \
    LOG(@"Hook result %p", result);                              \
    *(void **)(&orig) = (void *)result;                          \
  }

// Note to not prepend an underscore to the symbol. See Notes on the Apple manpage (https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dlsym.3.html)
#define HOOKSYM(sym, ptr, org) MSHookFunction((void *)dlsym((void *)RTLD_DEFAULT, sym), (void *)ptr, (void **)&org)
#define HOOKSYM_NO_ORIG(sym, ptr) MSHookFunction((void *)dlsym((void *)RTLD_DEFAULT, sym), (void *)ptr, NULL)
#define getSym(symName) dlsym((void *)RTLD_DEFAULT, symName)

uint64_t getRealOffset(uint64_t offset)
{
  return KittyMemory::getAbsoluteAddress([common getFrameworkName], offset);
}

// Patching offset with KittyMemory
void patchOffsetKitty(uint64_t offset, std::string hexBytes)
{
  MemoryPatch patch = MemoryPatch::createWithHex([common getFrameworkName], offset, hexBytes);
  if (!patch.isValid())
  {
    LOG(@"Invalid patch, failing offset: 0x%llX, please re-check the hex you entered.", offset);
    return;
  }
  if (!patch.Modify())
  {
    LOG(@"Something went wrong while patching this offset: 0x%llX", offset);
  }
}

// Patch offset for Non-Jailbreak
// Thanks https://github.com/itsPow45/iOS-Jailed-Runtime-Offset-Patching-and-Hooking/blob/main/Tweak.xm
void patchOffset(uint64_t vaddr, std::string hexBytes)
{
  char *frameworkName = (char *)[common getFrameworkName];
  const uint64_t imageBase = 0x100000000;
  if (vaddr > imageBase)
    vaddr = vaddr - imageBase;

  if (!KittyUtils::String::ValidateHex(hexBytes))
  {
    LOG(@"Invalid hex string: %s, please re-check the hex you entered.", hexBytes.c_str());
    return;
  }

  // Active patch
  ActiveCodePatch(
      frameworkName,
      vaddr,
      hexBytes.data());

  // Patch
  NSString *msg = StaticInlineHookPatch(
      frameworkName,
      vaddr,
      hexBytes.data());

  LOG(@"Patch result: %@", msg);
}

void restorePatchOffset(uint64_t vaddr, std::string hexBytes)
{
  char *frameworkName = (char *)[common getFrameworkName];

  // Deactive patch
  DeactiveCodePatch(
      frameworkName,
      vaddr,
      hexBytes.data());
}
