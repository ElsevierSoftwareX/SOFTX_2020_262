function [gpu_comp,g]=get_gpu_comp_stat()
g=[];
gpu_comp=0;
fig=findobj(0,'Type','figure','-and','Name','ESP3');

if ~isempty(fig)
    curr_disp=get_esp3_prop('curr_disp');
    
    if ~isempty(curr_disp)
        if curr_disp.GPU_computation == 0
            return;
        end
    end
end

try
        if ~isdeployed()
            [gpu_comp,~]=license('checkout','Distrib_Computing_Toolbox');
        else
            gpu_comp=1;
        end
    if gpu_comp
        g = gpuDevice;
        if str2double(g.ComputeCapability)>=3&&g.SupportsDouble&&g.DriverVersion>7&&g.DeviceSupported>0&&g.ToolkitVersion>=9.1
            gpu_comp=g.DeviceSupported>0&&g.DeviceSelected>0;
        else
            gpu_comp=0;
        end
    end
    
catch err
    if strcmpi(err.message,'parallel:gpu:device:DriverRedirect')
        fprintf('There is a problem with the graphics driver or with this GPU device./nBe sure that you have a supported GPU and that the latest driver is installed.\Otherwise, disable GPU computation inthe display menu...');
    end
    g=[];
    gpu_comp=0;
end

end
