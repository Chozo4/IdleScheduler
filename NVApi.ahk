class NvAPI
{
    static DllFile := (A_PtrSize = 8) ? "nvapi64.dll" : "nvapi.dll"
    static hmod
    static init := NvAPI.ClassInit()
    static DELFunc := OnExit(ObjBindMethod(NvAPI, "_Delete"))

    static NVAPI_GENERIC_STRING_MAX   := 4096
    static NVAPI_MAX_LOGICAL_GPUS     :=   64
    static NVAPI_MAX_PHYSICAL_GPUS    :=   64
    static NVAPI_MAX_VIO_DEVICES      :=    8
    static NVAPI_SHORT_STRING_MAX     :=   64

    static ErrorMessage := False

    ClassInit()
    {
        if !(NvAPI.hmod := DllCall("LoadLibrary", "Str", NvAPI.DllFile, "UPtr"))
        {
            MsgBox, 16, % A_ThisFunc, % "LoadLibrary Error: " A_LastError
            ExitApp
        }
        if (NvStatus := DllCall(DllCall(NvAPI.DllFile "\nvapi_QueryInterface", "UInt", 0x0150E828, "CDECL UPtr"), "CDECL") != 0)
        {
            MsgBox, 16, % A_ThisFunc, % "NvAPI_Initialize Error: " NvStatus
            ExitApp
        }
    }

; ###############################################################################################################################

    GPU_GetDynamicPstatesInfoEx(hPhysicalGpu := 0)
    {
        static GPU_GetDynamicPstatesInfoEx := DllCall(NvAPI.DllFile "\nvapi_QueryInterface", "UInt", 0x60DED2ED, "CDECL UPtr")
        static NVAPI_MAX_GPU_UTILIZATIONS := 8
        static NV_GPU_UTILIZATION_DOMAIN_ID := ["GPU", "FB", "VID", "BUS"]
        static NV_GPU_DYNAMIC_PSTATES_INFO_EX := 8 + (8 * NVAPI_MAX_GPU_UTILIZATIONS)
        if !(hPhysicalGpu)
            hPhysicalGpu := NvAPI.EnumPhysicalGPUs()[1]
        VarSetCapacity(pDynamicPstatesInfoEx, NV_GPU_DYNAMIC_PSTATES_INFO_EX, 0), NumPut(NV_GPU_DYNAMIC_PSTATES_INFO_EX | 0x10000, pDynamicPstatesInfoEx, 0, "UInt")
        if !(NvStatus := DllCall(GPU_GetDynamicPstatesInfoEx, "Ptr", hPhysicalGpu, "Ptr", &pDynamicPstatesInfoEx, "CDECL"))
        {
            PSTATES := {}
			PSTATES.version := NumGet(pDynamicPstatesInfoEx, 0, "UInt")
            PSTATES.Enabled := NumGet(pDynamicPstatesInfoEx, 4, "UInt") & 0x1
            OffSet := 8
            for Index, Domain in NV_GPU_UTILIZATION_DOMAIN_ID
            {
                PSTATES[Domain, "bIsPresent"] := NumGet(pDynamicPstatesInfoEx, Offset, "UInt") & 0x1
                PSTATES[Domain, "percentage"] := NumGet(pDynamicPstatesInfoEx, Offset + 4, "UInt")
                Offset += 8
            }
            return PSTATES
        }
        return NvAPI.GetErrorMessage(NvStatus)
    }


; ###############################################################################################################################

    EnumPhysicalGPUs()
    {
        static EnumPhysicalGPUs := DllCall(NvAPI.DllFile "\nvapi_QueryInterface", "UInt", 0xE5AC921F, "CDECL UPtr")
        VarSetCapacity(nvGPUHandle, 4 * NvAPI.NVAPI_MAX_PHYSICAL_GPUS, 0)
        if !(NvStatus := DllCall(EnumPhysicalGPUs, "Ptr", &nvGPUHandle, "UInt*", pGpuCount, "CDECL"))
        {
            GPUH := []
            loop % pGpuCount
                GPUH[A_Index] := NumGet(nvGPUHandle, 4 * (A_Index - 1), "Int")
            return GPUH
        }
        return NvAPI.GetErrorMessage(NvStatus)
    }

; ###############################################################################################################################

    _Delete()
    {
        DllCall(DllCall(NvAPI.DllFile "\nvapi_QueryInterface", "UInt", 0xD22BDD7E, "CDECL UPtr"), "CDECL")
        DllCall("FreeLibrary", "Ptr", NvAPI.hmod)
    }
}