function [f_vec,TS_f,SD_f]=TS_freq_response_func(layer,varargin)

p = inputParser;

addRequired(p,'layer',@(x) isa(x,'layer_cl'));
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl')||isstruct(x));
addParameter(p,'idx_freq',1,@isnumeric);
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

load_bar_comp=p.Results.load_bar_comp;

range_tr=trans_obj.get_transceiver_range();

reg_bool=isa(reg_obj,'region_cl');

if reg_bool
    reg_obj_main=reg_obj;
    [regs,idx_freq_end]=layer.generate_regions_for_other_freqs(p.Results.idx_freq,reg_obj,[]);
else
    idx_r=reg_obj.idx_r;
    range_peak=range_tr(idx_r)';
    reg_obj_main.Target_range=range_peak;
    reg_obj_main.Ping_number=reg_obj.Ping_number;
end

f_vec=[];
TS_f=[];
SD_f=[];

[~,idx_sort_f]=sort(layer.Frequencies);

[cal_fm_cell,origin_used]=layer.get_fm_cal([]);


for uui=idx_sort_f
    
    if reg_bool
        reg=regs(idx_freq_end==uui);
    else
        reg=reg_obj_main;
    end
    
    if isempty(reg)
        reg=reg_obj_main;
    end
    trans_obj=layer.Transceivers(uui);
    
    [TS_f_tmp,f_vec_temp,~,~]=trans_obj.TS_f_from_region(reg,'cal',cal_fm_cell{uui},'load_bar_comp',load_bar_comp,'mode','max_reg');
    TS_f_tmp=permute(TS_f_tmp,[1 3 2]);
    tsf_f_tmp=(10.^(TS_f_tmp/10));
    
    if isempty(TS_f_tmp)
        continue;
    end
    
    if reg_bool
        SD_f=[SD_f nanstd(TS_f_tmp,1,1)];
        TS_f=[TS_f 10*log10(nanmean(tsf_f_tmp,1))];
        f_vec=[f_vec f_vec_temp];
    else
        TS_f=[TS_f;10*log10(tsf_f_tmp')];
        f_vec=[f_vec;f_vec_temp'];
    end
  
end


if ~isempty(f_vec)
    
    if reg_bool
        [f_vec,idx_sort]=sort(f_vec);
        TS_f=TS_f(idx_sort);
        
        layer.add_curves(curve_cl('XData',f_vec/1e3,...
            'YData',TS_f,...
            'SD',SD_f,...
            'Type','ts_f',...
            'Xunit','kHz',...
            'Yunit','dB',...
            'Tag',reg_obj.Tag,...
            'Name',sprintf('%s %.0f %.0f kHz',reg_obj.Name,reg_obj.ID,layer.Frequencies(p.Results.idx_freq)/1e3),...
            'Unique_ID',reg_obj.Unique_ID));
    else
        [f_vec,idx_sort]=sort(f_vec(:,1));
        uid=generate_Unique_ID(size(TS_f,2));
        
        for itt=1:size(TS_f,2)
            layer.add_curves(curve_cl('XData',f_vec/1e3,...
                'YData',TS_f(idx_sort,itt),...
                'SD',[],...
                'Type','ts_f',...
                'Xunit','kHz',...
                'Yunit','dB',...
                'Tag','ST',...
                'Name',sprintf('%s %d %.0f kHz','Single Target',itt,layer.Frequencies(p.Results.idx_freq)/1e3),...
                'Unique_ID',['single_target' uid{itt}]));
        end
    end
    
end


end
