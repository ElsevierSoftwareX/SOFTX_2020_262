function notch_filter_transceiver(trans_obj,env_data_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'env_data_obj',@(obj) isa(obj,'env_data_cl'));
addParameter(p,'bands_to_notch',[],@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);

parse(p,trans_obj,env_data_obj,varargin{:});
band_f=p.Results.bands_to_notch;

FreqStart_tot=(trans_obj.get_params_value('FrequencyStart',[]));
FreqEnd_tot=(trans_obj.get_params_value('FrequencyEnd',[]));
f_s_sig_tot=round((1./(trans_obj.get_params_value('SampleInterval',[]))));

[Vals,unique_freqs,triple_ID]=unique([FreqStart_tot(:) FreqEnd_tot(:) f_s_sig_tot(:)],'rows');
Rwt_rx=trans_obj.Config.Impedance;
Ztrd=trans_obj.Config.Ztrd;
if ~strcmpi(trans_obj.Mode,'CW')
    for iFreq=1:size(Vals,1)
        FreqStart=Vals(iFreq,1);
        FreqEnd=Vals(iFreq,2);
        f_s_sig=Vals(iFreq,3);
        idx_sub_pings=find(triple_ID==unique_freqs(iFreq));
        band_f_tmp=band_f;
        band_f_tmp(band_f_tmp<FreqStart)=FreqStart;
        band_f_tmp(band_f_tmp>FreqEnd)=FreqEnd;
        n_filt_length=ceil(f_s_sig/1e2);
        
        band_f_based=band_f_tmp-f_s_sig;
        f_vec_based=linspace(-f_s_sig/2,f_s_sig/2,n_filt_length);
        
        amp_filt=ones(size(f_vec_based));
        f_vec=linspace(nanmin(FreqEnd,FreqStart),nanmax(FreqEnd,FreqStart),n_filt_length);
        
        for ib=1:size(band_f,1)
            if any(f_vec>=nanmin(band_f(ib,:))&f_vec<=nanmax(band_f(ib,:)))
                amp_filt(f_vec_based>=nanmin(band_f_based(ib,:))&f_vec_based<=nanmax(band_f_based(ib,:)))=0;
            end
        end
        block_size = nanmin(ceil(p.Results.block_len/nanmax(trans_obj.Data.Nb_samples)),numel(idx_sub_pings));
        num_ite = ceil(numel(idx_sub_pings)/block_size);
        if ~all(amp_filt>0)
            mbFilt = designfilt('arbmagfir','FilterOrder',60, ...
                'Frequencies',f_vec_based,'Amplitudes',amp_filt, ...
                'SampleRate',f_s_sig);
            
            
        end
        % initialize progress bar
        if ~isempty(p.Results.load_bar_comp)
            p.Results.load_bar_comp.progress_bar.setText(sprintf('Notch Filtering %.0fkHz',trans_obj.get_params_value('Frequency',1)/1e3));
            set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
        end
        
        for ui = 1:num_ite
            idx_sub_sub_pings = idx_sub_pings((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_sub_pings)));
            if ~all(amp_filt>0)
                for iping=idx_sub_sub_pings
                    y_c=trans_obj.Data.get_subdatamat([],iping,'field','y_real')+1i*trans_obj.Data.get_subdatamat([],iping,'field','y_imag');
                    y_c_filtered = filter(mbFilt,y_c);
                    trans_obj.Data.replace_sub_data_v2('y_real_filtered',real(y_c_filtered),[],iping);
                    trans_obj.Data.replace_sub_data_v2('y_imag_filtered',imag(y_c_filtered),[],iping);
                    power=(trans_obj.Config.NbQuadrants*(abs(y_c_filtered)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd);
                    trans_obj.Data.replace_sub_data_v2('power',power,[],iping);
                end
            else
                for iping=idx_sub_sub_pings
                    y_c=trans_obj.Data.get_subdatamat([],iping,'field','y_real')+1i*trans_obj.Data.get_subdatamat([],iping,'field','y_imag');
                    trans_obj.Data.replace_sub_data_v2('y_real_filtered',real(y_c),[],iping);
                    trans_obj.Data.replace_sub_data_v2('y_imag_filtered',imag(y_c),[],iping);
                    power=(trans_obj.Config.NbQuadrants*(abs(y_c)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd);
                    trans_obj.Data.replace_sub_data_v2('power',power,[],iping);
                    
                end
            end
            
            % update progress bar
            if ~isempty(p.Results.load_bar_comp)
                set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
            end
        end
    end
    trans_obj.computeSpSv_v3(p.Results.env_data_obj,'load_bar_comp',p.Results.load_bar_comp);
end
end