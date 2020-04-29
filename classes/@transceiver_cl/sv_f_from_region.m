function [Sv_f,f_vec,pings,r_tot]=sv_f_from_region(trans_obj,reg_obj,varargin)

p = inputParser;
addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addRequired(p,'reg_obj',@(x) isa(x,'region_cl'));
addParameter(p,'envdata',env_data_cl,@(x) isa(x,'env_data_cl'));
addParameter(p,'cal',[],@(x) isempty(x)|isstruct(x));
addParameter(p,'att_model','doonan',@(s) ismember(s,{'fandg' 'doonan'}));
addParameter(p,'output_size','3D',@ischar);
addParameter(p,'sliced_output',0,@isnumeric);
addParameter(p,'load_bar_comp',[],@(x) isempty(x)|isstruct(x));
parse(p,trans_obj,reg_obj,varargin{:});

field='sv';
if ismember('svdenoised',trans_obj.Data.Fieldname)
    field='svdenoised';
end

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText(sprintf('Processing Sv(f) estimation at %.0fkHz',trans_obj.Params.Frequency(1)/1e3));
end

switch trans_obj.Mode
    
    case 'FM'
        range_tr=trans_obj.get_transceiver_range(reg_obj.Idx_r);
        pings=trans_obj.get_transceiver_pings(reg_obj.Idx_pings);
        
        [~,~,~,~,bad_trans_vec,~,below_bot_mask,~]=trans_obj.get_data_from_region(reg_obj,...
            'field',field);
        
        pings(bad_trans_vec)=[];
        if isempty(pings)
            Sv_f=[];
            f_vec=[];
            pings=[];
            r_tot=[];
            return;
        end
        [~,Np]=trans_obj.get_pulse_length(1);
        
        if ~isempty(p.Results.load_bar_comp)
            set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(pings),'Value',0);
        end
        
        if p.Results.sliced_output>0
            output_size='3D';
            cell_h=p.Results.sliced_output;
        else
            output_size=p.Results.output_size;
            cell_h=0;
        end
        
        win_size=3*Np;
        
        [~,f_vec,r_tot]=trans_obj.processSv_f_r_2(p.Results.envdata,pings(1),range_tr,win_size,p.Results.cal,p.Results.att_model,output_size,cell_h);
        
        Sv_f=nan(length(pings),length(r_tot),length(f_vec));
        
        for i=1:length(pings)
            if ~isempty(p.Results.load_bar_comp)
                set(p.Results.load_bar_comp.progress_bar ,'Value',i);
            end
            [Sv_f(i,:,:),~,~]=trans_obj.processSv_f_r_2(p.Results.envdata,pings(i),range_tr,win_size,p.Results.cal,p.Results.att_model,output_size,cell_h);
        end
        
        
%         if strcmpi(trans_obj.Mode,'FM')
%             [f_min_3dB,f_max_3dB]=trans_obj.get_3dB_f();
%             
%             idx_f_keep=f_vec>=f_min_3dB&f_vec<=f_max_3dB;
%             
%             Sv_f(:,:,~idx_f_keep)=nan;
%             Sv_f(:,:,~idx_f_keep')=nan;
%             
%         end
        
        
    case 'CW'
        output_reg=trans_obj.integrate_region(reg_obj,'keep_bottom',1,'keep_all',0);
        pings=round((output_reg.Ping_S+output_reg.Ping_E)/2);
        r_tot=trans_obj.get_transceiver_range(ceil(nanmean((output_reg.Sample_S+output_reg.Sample_E)/2,2)));
        f_vec=trans_obj.Params.Frequency(pings(1));
        Sv_f=nan(length(pings),length(r_tot),length(f_vec));
        Sv_f(:,:,1)=pow2db_perso(output_reg.Sv_mean_lin');
        
end


end
