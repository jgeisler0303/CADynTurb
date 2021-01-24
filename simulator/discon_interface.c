#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>

typedef void (__declspec(dllexport) __cdecl *DISCON_t)(float *avrSwap, int32_t *aviFail, char * accInfile, char *avcOutname, char *avcMsg);

int23_t aviFail
char accInfile[257];
char avcOutname[257];
char avcMsg[257];

int main(void) {
    void *handle;
    double (*cosine)(double);
    char *error;
    
    handle = dlopen("DISCON.DLL", RTLD_NOW);
    if (!handle) {
        fprintf(stderr, "%s\n", dlerror());
        exit(EXIT_FAILURE);
    }
    
    dlerror();    /* Clear any existing error */
    
    cosine = (DISCON_t) dlsym(handle, "DISCON");
    
    /* According to the ISO C standard, casting between function
     *      pointers and 'void *', as done above, produces undefined results.
     *      POSIX.1-2003 and POSIX.1-2008 accepted this state of affairs and
     *      proposed the following workaround:
     * 
     *(void **) (&cosine) = dlsym(handle, "cos");
     * 
     *      This (clumsy) cast conforms with the ISO C standard and will
     *      avoid any compiler warnings.
     * 
     *      The 2013 Technical Corrigendum to POSIX.1-2008 (a.k.a.
     *      POSIX.1-2013) improved matters by requiring that conforming
     *      implementations support casting 'void *' to a function pointer.
     *      Nevertheless, some compilers (e.g., gcc with the '-pedantic'
     *      option) may complain about the cast used in this program. */
    
    error = dlerror();
    if (error != NULL) {
        fprintf(stderr, "%s\n", error);
        exit(EXIT_FAILURE);
    }
    
    printf("%f\n", );
    dlclose(handle);
    exit(EXIT_SUCCESS);
}
