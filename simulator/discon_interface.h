#ifndef DISCON_INTERFACE_H_
#define DISCON_INTERFACE_H_

#include <stdlib.h>
#ifdef __linux__
    #include <dlfcn.h>
#elif _WIN32
    #include <windows.h>
    #include <winbase.h>
    #include <windef.h>
    #include <system_error>
#else
    #error Platform not supported
#endif
#include <stdint.h>
#include <cstring>
#include <string>
#include <utility>
#include <exception>

#include "discon_swap.h"

const int discon_string_len= 256;

class DISCON_Exception: public std::exception {
public:
    DISCON_Exception(const std::string& msg= "Abstract DISCON exception", int32_t fail_code= 0) :
        m_msg(msg),
        fail_code(fail_code)
    {}
    
    virtual const char* what() const throw () {
        printf("fail code %d\n", fail_code);
        return m_msg.c_str();
    }
    
    const std::string m_msg;
    const int32_t fail_code;
};


class DISCON_DLL {
public:
    DISCON_DLL()
      : handle(nullptr),
        DISCON(nullptr)
    {}
    
    virtual ~DISCON_DLL() {
        close();
    }
    
    DISCON_DLL(DISCON_DLL&& other) noexcept
      : DISCON_DLL()
    {
        swap(*this, other);
    }
    
    DISCON_DLL& operator=(DISCON_DLL other) {
        swap(*this, other);
        
        return *this;
    }

    #if _WIN32
    std::string getLastErrorStr() {
//     LPVOID lpMsgBuf;
//     LPVOID lpDisplayBuf;
//     DWORD dw = GetLastError(); 
// 
//     FormatMessage(
//         FORMAT_MESSAGE_ALLOCATE_BUFFER | 
//         FORMAT_MESSAGE_FROM_SYSTEM |
//         FORMAT_MESSAGE_IGNORE_INSERTS,
//         NULL,
//         dw,
//         MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
//         (LPTSTR) &lpMsgBuf,
//         0, NULL );
// 
//     // Display the error message and exit the process
// 
//     lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, 
//         (lstrlen((LPCTSTR)lpMsgBuf) + lstrlen((LPCTSTR)lpszFunction) + 40) * sizeof(TCHAR)); 
//     StringCchPrintf((LPTSTR)lpDisplayBuf, 
//         LocalSize(lpDisplayBuf) / sizeof(TCHAR),
//         TEXT("%s failed with error %d: %s"), 
//         lpszFunction, dw, lpMsgBuf); 
//     MessageBox(NULL, (LPCTSTR)lpDisplayBuf, TEXT("Error"), MB_OK); 
        DWORD error = GetLastError();
        return std::system_category().message(error);
    }
    #endif

    void close() {
        if(handle!=nullptr)
            #ifdef __linux__
                dlclose(handle);
            #elif _WIN32
                FreeLibrary(handle);
            #endif
        
        handle= nullptr;
        DISCON= nullptr;
    }
    
    void open(const std::string &dll_name) {
        char *error;
        
        #ifdef __linux__
            handle= dlopen(dll_name.c_str(), RTLD_NOW);
            error= dlerror();
            if(!handle) {
                throw DISCON_Exception("Error opening handle for dll \"" + dll_name + "\": " + std::string(error));
            }
            
            DISCON= (DISCON_t) dlsym(handle, "DISCON");
            error= dlerror();
            if(error!=nullptr) {
                dlclose(handle);
                handle= nullptr;
                
                throw DISCON_Exception("Error getting DISCON function from dll \"" + dll_name + "\": " + std::string(error));
            }
        #elif _WIN32
            handle= LoadLibrary(dll_name.c_str());
            if(!handle) {
                throw DISCON_Exception("Error opening handle for dll \"" + dll_name + "\": " + getLastErrorStr());
            }
        
            DISCON= (DISCON_t) GetProcAddress(handle, "DISCON");
            if(!DISCON) {
                FreeLibrary(handle);
                handle= nullptr;
                
                throw DISCON_Exception("Error getting DISCON function from dll \"" + dll_name + "\": " + getLastErrorStr());
            }
        #endif        
    }
        
    int32_t call(avrSwap_t *avrSwap, char *accInfile, char *accOutfile, char *avcMsg) {
        if(DISCON==nullptr)
            throw DISCON_Exception("Trying to call DISCON but function pointer is null");
            
        int32_t aviFail= 0;
        
        DISCON(avrSwap->array, &aviFail, accInfile, accOutfile, avcMsg);
        if(aviFail<0)
            throw DISCON_Exception("Call to DISCON failed: \"" + std::string(avcMsg) + "\"", aviFail);
        
        return aviFail;
    }
    
    friend void swap(DISCON_DLL& first, DISCON_DLL& second) {  // nothrow
        // enable ADL (not necessary in our case, but good practice)
        using std::swap;
        
        swap(first.DISCON, second.DISCON);
        swap(first.handle, second.handle);
    }

protected:
    // typedef void (__declspec(dllexport) __cdecl *DISCON_t)(float *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg);
    typedef void(*DISCON_t)(float *avrSwap, int32_t *aviFail, char *accInfile, char *avcOutname, char *avcMsg);
    
    #ifdef __linux__
        void *handle;
    #elif _WIN32
        HINSTANCE handle;
    #endif
    DISCON_t DISCON;    
};

class DISCON_Interface : protected DISCON_DLL, public avrSwap_t {
public:
    DISCON_Interface(std::string dll_name = "./DISCON.dll", std::string in_name = "", std::string out_name = "")
      : DISCON_DLL()
    {
        for(int i= 0; i<256; ++i) array[i]= 0.0;
        
        open(dll_name);
        setInfile(in_name);
        setOutfile(out_name);
        strcpy(avcMsg, "");
        
        sim_status= 0;
        max_msg_char= discon_string_len-1;
        
        logging_max= 0;
        logging_idx= 0;
        outfile_max= discon_string_len-1;
        
    }
    
    virtual ~DISCON_Interface() {
        finish();
    }
    
    void setInfile(std::string in_name = "") {
        strcpy(accInfile, in_name.c_str());
        infile_len= strlen(accInfile);        
    }
    
    void setOutfile(std::string out_name = "") {
        strcpy(accOutfile, out_name.c_str());
        outfile_len= strlen(accOutfile);
    }
    
    int32_t init() {
        int32_t fail_code= 0;
        
        if(sim_status==-1)
            throw DISCON_Exception("Trying to initialize already finished DISCON");
        
        if(sim_status==0) {
            strcpy(avcMsg, "");
            fail_code= call(this, accInfile, accOutfile, avcMsg);
            
            sim_status= 1;
        }
        return fail_code;
    }
    
    int32_t finish() {
        if(sim_status==-1) {
            strcpy(avcMsg, "DISCON was already finished, not finishing again");
            return 1;
        }
            
        sim_status= -1;
        strcpy(avcMsg, "");
        return call(this, accInfile, accOutfile, avcMsg);
    }
    
    int32_t run() {
        if(sim_status==-1)
            throw DISCON_Exception("Trying to run already finished DISCON");
        
        init();
        
        strcpy(avcMsg, "");
        return call(this, accInfile, accOutfile, avcMsg);
    }        
    
    std::string getMessage() {
        return std::string(avcMsg);
    }
    
protected:
    char *error;
    
    char accInfile[discon_string_len];
    char accOutfile[discon_string_len];
    char avcMsg[discon_string_len];
};

#endif /* DISCON_INTERFACE_H_ */
