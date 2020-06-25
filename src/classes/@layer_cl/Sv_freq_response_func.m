function Sv_freq_response_func(layer,varargin)

p = inputParser;

addRequired(p,'layer',@(x) isa(x,'layer_cl'));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'idx_freq',1,@isnumeric);
addParameter(p,'sliced',false,@islogical);
addParameter(p,'load_bar_comp',[]);

parse(p,layer,varargin{:});

trans_obj = layer.Transceivers(p.Results.idx_freq);

if isempty(p.Results.reg_obj)
    idx_r=(1:length(trans_obj.get_transceiver_range()))';
    idx_pings=1:length(trans_obj.get_transceiver_pings());
    [~,Np_p]=trans_obj.get_pulse_length();
    idx_r(idx_r<3*nanmax(Np_p))=[];
    reg_obj=region_cl('Idx_r',idx_r,'Idx_pings',idx_pings);
else
    reg_obj=p.Results.reg_obj;

end

[cal_fm_cell,origin_used] =layer.get_fm_cal([]);

[regs,idx_freq_end]=layer.generate_regions_for_other_freqs(idx_freq,reg_obj,[]);

for uui=1:length(layer.Frequencies)
    reg=regs(idx_freq_end==uui);
    
    if isempty(reg)
        reg=reg_obj;
    end
    
    cal=cal_fm_cell{uui};

    if sliced>0
        cell_h=reg.Cell_h;
    else
        cell_h=0;
    end
    output_size='2D';
    [Sv_f_out,f_vec_temp,pings,r_f]=layer.Transceivers(uui).sv_f_from_region(reg,...
        'envdata',layer.EnvData,'cal',cal,'output_size',output_size,'sliced_output',cell_h,'load_bar_comp',load_bar_comp);
    
    sv_f_temp=10.^(Sv_f_out/10);
    
    if isempty(sv_f_temp)
        continue;
    end
    
    if sliced==0
        if size(sv_f_temp,2)>1
            Sv_f_temp=10*log10(nanmean(nanmean(sv_f_temp)));
            SD_f_temp=nanstd(10*log10(nanmean(sv_f_temp)));
        else
            Sv_f_temp=10*log10(nanmean(sv_f_temp,1));
            SD_f_temp=zeros(size(Sv_f_temp));
        end
        
        Sv_f_temp=permute(Sv_f_temp,[2 3 1]);
        SD_f_temp=permute(SD_f_temp,[2 3 1]);
        r_tmp=nanmean(r_f);
    else
        
        idx_slice_r=round((r_f-r_f(1))/cell_h)+1;
        idx_slice=repmat(idx_slice_r',length(pings),1,length(f_vec_temp));
        idx_pings=repmat((1:length(pings))',1,length(r_f),length(f_vec_temp));
        idx_f=repmat(shiftdim((1:length(f_vec_temp)),-1),size(Sv_f_out,1),length(r_f),1);
        sv_f_temp=(accumarray([idx_pings(:) idx_slice(:) idx_f(:)],db2pow(Sv_f_out(:)),[],@nanmean));
        
        Sv_f_temp=shiftdim(pow2db_perso(nanmean(sv_f_temp,1)),1);
        SD_f_temp=shiftdim(pow2db_perso(nanstd(sv_f_temp,1,1)),1);
        r_tmp=accumarray(idx_slice_r,r_f,[],@nanmean);
        
    end
    
    
    if uui>1
        SD_f_temp_final=nan(size(r_vec,1),size(SD_f_temp,2));
        Sv_f_temp_final=nan(size(r_vec,1),size(Sv_f_temp,2));
        f_vec_temp_final=f_vec_temp;
        r_tmp_final=nan(size(r_vec,1),1);
        for iv=1:size(r_vec,1)
            [~,idx_r]=nanmin(abs(r_vec(iv)-r_tmp));
            SD_f_temp_final(iv,:)=SD_f_temp(idx_r,:);
            Sv_f_temp_final(iv,:)=Sv_f_temp(idx_r,:);
            r_tmp_final(iv)=r_tmp(idx_r);
        end
        SD_f=[SD_f SD_f_temp_final];
        Sv_f=[Sv_f Sv_f_temp_final];
        f_vec=[f_vec f_vec_temp_final];
        r_vec=[r_vec r_tmp_final];
    else
        SD_f= SD_f_temp;
        Sv_f= Sv_f_temp;
        f_vec=f_vec_temp;
        r_vec=r_tmp;
    end
end

r_vec_tmp=nanmean(r_vec,2);
[f_vec,idx_sort]=sort(f_vec);
Sv_f=Sv_f(:,idx_sort);
SD_f=SD_f(:,idx_sort);


if~isempty(f_vec)
    for i=1:size(Sv_f,1)
        layer.add_curves(curve_cl('XData',f_vec/1e3,...
            'YData',Sv_f(i,:),...
            'SD',SD_f(i,:),...
            'Type','sv_f',...
            'Xunit','kHz',...
            'Yunit','dB',...
            'Tag',reg_obj.Tag,...
            'Name',sprintf('%s %.0f %.0f kHz @ %.1fm',reg_obj.Name,reg_obj.ID,layer.Frequencies(idx_freq)/1e3,r_vec(i,1)),...
            'Unique_ID',sprintf('%s_%.0f',reg_obj.Unique_ID,r_vec(i,1))));
    end
end

end