//
// PEObjcCommonsConstantsInternal.h
//

#ifndef PEObjc_Commons_PEObjcCommonsConstantsInternal_h
#define PEObjc_Commons_PEObjcCommonsConstantsInternal_h

//Xcode 5 compatibility check
#ifdef NSFoundationVersionNumber_iOS_6_1
#define PE_IS_IOS7_OR_GREATER (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
#else
#define PE_IS_IOS7_OR_GREATER NO
#endif

//Xcode 6 compatibility check
#ifdef NSFoundationVersionNumber_iOS_7_1
#define PE_IS_IOS8_OR_GREATER (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
#else
#define PE_IS_IOS8_OR_GREATER NO
#endif

#endif
