function block_len_def=get_block_len(nb_blocks_in_mem,device)

if strcmpi(device,'gpu')
    [gpu_comp,~]=get_gpu_comp_stat();
else
    gpu_comp=0;
end

if gpu_comp&&strcmpi(device,'gpu')
    mem_struct=gpuDevice();
    if (mem_struct.AvailableMemory==0)
        gpuDevice([]);
        mem_struct=gpuDevice();
    end
    block_len_def=ceil(mem_struct.AvailableMemory/8/nb_blocks_in_mem/4);
else
    if ispc()
        mem_struct=memory;
        block_len_def=ceil(mem_struct.MaxPossibleArrayBytes/8/nb_blocks_in_mem/4);
    else
        block_len_def=ceil(5*1e9/8/nb_blocks_in_mem/4);
    end
end

block_len_def = nanmax(block_len_def,1e2);

end
