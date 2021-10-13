#ifndef UTILITY_H
#define UTILITY_H

#define OffsetOf(type, member) ((unsigned)&(((type*)0)->member))

#define ContainerOf(pointer, type, member) ({                \
		const typeof(((type*)0)->member)* __ptr = (pointer); \
		(type*)((char*)__ptr - OffsetOf(type, member));      \
		})

void Delay(int n);
char* StrCpy(char* dst, const char* src);
#endif // UTILITY_H

