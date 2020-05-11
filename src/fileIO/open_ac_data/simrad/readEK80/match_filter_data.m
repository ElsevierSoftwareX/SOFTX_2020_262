function [data,mode]=match_filter_data(data,params,filters)


if params.FrequencyStart(1)~=params.FrequencyEnd(1)
    mode='FM';
    
    [~,y_tx_matched]=generate_sim_pulse(params,filters(1),filters(2));
    Np=numel(y_tx_matched);
    
    nb_chan=sum(contains(fieldnames(data),'comp_sig'));
    
    for i=1:nb_chan
        s=data.(sprintf('comp_sig_%1d',i));
        
        [nb_s,nb_pings]=size(s);
        
        data.ping_num=(1:nb_pings);
        
        val_sq=sum(abs(y_tx_matched).^2);
        n = Np + nb_s - 1;
        %gpu_comp=get_gpu_comp_stat();
        gpu_comp=0;
        
        if gpu_comp>0
            a=fft(gpuArray(y_tx_matched),n);
            b=fft(gpuArray(s),n,1);
            yc_temp = gather(ifft(a.*b,n,1)/val_sq);
        else            
            yc_temp =ifft(fft(y_tx_matched,n).*fft(s,n,1)/val_sq);
        end
        
        i0=ceil(Np/2);
        d_t=yc_temp(i0:i0+nb_s-1,:);
        
        data.(sprintf('comp_sig_%1d',i))=d_t;
    end
    
else
    mode='CW';
end
