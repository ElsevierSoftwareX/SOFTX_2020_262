referefunction[cal_cw,cal_fm]=TS_calibration_curves_func(main_figure,layer,select)

cal_cw=[];
cal_fm={};


int_meth='linear';
ext_meth=nan;


update_algos(main_figure,'algo_name',{'SingleTarget'});

load_bar_comp=getappdata(main_figure,'Loading_bar');

if isempty(layer)
    layer=get_current_layer();
end

curr_disp=get_esp3_prop('curr_disp');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
ah=axes_panel_comp.echo_obj.main_ax;

[cmap,col_ax,~,col_grid,~,~]=init_cmap(curr_disp.Cmap);

[~,idx_freq]=layer.get_trans(curr_disp);

calibration_tab_comp=getappdata(main_figure,'Calibration_tab');
env_tab_comp=getappdata(main_figure,'Env_tab');

sphere_list=get(calibration_tab_comp.sphere,'String');
sph=list_spheres(sphere_list{get(calibration_tab_comp.sphere,'value')});

att_list=get(env_tab_comp.att_model,'String');
att_model=att_list{get(env_tab_comp.att_model,'value')};

%f_vec_save=[];
if isempty(select)
    list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(layer.Frequencies/1e3), layer.ChannelID,'un',0);
    
    if numel(list_freq_str)>1
        [select,val] = listdlg_perso(main_figure,'Choose Frequencies to calibrate',list_freq_str);
        
        if val==0||isempty(select)
            return;
        end
    else
        select=1;
    end
end
show_status_bar(main_figure);

cal_cw.SACORRECT=nan(1,numel(layer.Transceivers));
cal_cw.G0=nan(1,numel(layer.Transceivers));
cal_cw.EQA=nan(1,numel(layer.Transceivers));
cal_cw.AngleOffsetAlongship=nan(1,numel(layer.Transceivers));
cal_cw.AngleOffsetAthwartship=nan(1,numel(layer.Transceivers));
cal_cw.BeamWidthAlongship=nan(1,numel(layer.Transceivers));
cal_cw.BeamWidthAthwartship=nan(1,numel(layer.Transceivers));
cal_cw.RMS=nan(1,numel(layer.Transceivers));

cal_fm_tot=cell(1,numel(layer.Transceivers));

fields_fm_cal = get_cal_fm_fields();
           
alpha=cell(1,numel(layer.Transceivers));

for uui=select
    trans_obj=layer.Transceivers(uui);
    [tmp,~]=trans_obj.compute_absorption(layer.EnvData,'theoritical');
    alpha{uui}=tmp;
end

for uui=select
    
    trans_obj=layer.Transceivers(uui);
    trans_depth=trans_obj.get_transducer_depth();
    if isempty(trans_obj.Regions)
        continue;
    end
    new_region=trans_obj.Regions.merge_regions('overlap_only',0);
    t_mode_d=nanmean(trans_depth(new_region.Idx_pings));
    
    Freq=trans_obj.Config.Frequency;
    Freq_c=(trans_obj.get_params_value('FrequencyStart',1)+trans_obj.get_params_value('FrequencyEnd',1))/2;
    
    range_sph=mode(ceil(double(trans_obj.get_transceiver_range(new_region.Idx_r))*10/2)*2/10);
    
    t=layer.EnvData.Temperature;
    t_sphere=layer.EnvData.Temperature;
    s_sphere=layer.EnvData.Salinity;
    s=layer.EnvData.Salinity;
    
    d=nanmean(double(trans_obj.get_transceiver_range(1:nanmax(new_region.Idx_r))))+t_mode_d;
    
    density_at_sphere = seawater_dens(s_sphere, t_sphere, t_mode_d+range_sph);
    
    c_at_sphere = seawater_svel_un95(s_sphere, t_sphere, t_mode_d+range_sph);
    
    c = seawater_svel_un95(s, t, d);
    
    if trans_obj.get_params_value('FrequencyStart',1)>=120000|| trans_obj.get_params_value('FrequencyEnd',1)>=120000&&strcmp(att_model,'Doonan et al (2003)')
        att_model='Francois & Garrison (1982)';
    end
    
    
    if get(env_tab_comp.att_over,'value')==0
        switch att_model
            case 'Doonan et al (2003)'
                att_m='doonan';
            case 'Francois & Garrison (1982)'
                att_m='fandg';
        end
    else
        att_m='';
    end
    
    sphere_ts = spherets(2*pi*Freq_c/layer.EnvData.SoundSpeed,sph.diameter/2, c_at_sphere, ...
        sph.lont_c, sph.trans_c, density_at_sphere, sph.rho);
    
    [path_out,~]=fileparts(layer.Filename{1});
    log_file=fullfile(path_out,sprintf('cal_log_%dkHz_%s.txt',layer.Frequencies(uui)/1e3,datestr(now,'yyyymmdd_HHMMSS')));
    fid=[1 fopen(log_file,'w')];
    
    % print out the parameters
    for ifi=1:numel(fid)
        if fid(ifi)>=0
            fprintf(fid(ifi),['most common sphere depth (mode)= ' num2str(t_mode_d+range_sph) ' m\n']);
            fprintf(fid(ifi),['sound speed at sphere = ' num2str(c_at_sphere) ' m/s\n']);
            fprintf(fid(ifi),['density at sphere = ' num2str(density_at_sphere) ' kg/m^3\n']);
            fprintf(fid(ifi),['mean Absorption = ' num2str(nanmean(alpha{uui}(1:nanmax(new_region.Idx_r)))*1e3) ' dB/km\n']);
            fprintf(fid(ifi),['mean sound speed = ' num2str(c) ' m/s\n']);
            fprintf(fid(ifi),['sphere TS = ' num2str(sphere_ts) ' dB\n']);
        end
        
    end
    
    layer.EnvData.SVP.ori='constant';
    
    layer.layer_computeSpSv('new_soundspeed',c,'absorption',nanmean(alpha{uui}(1:nanmax(new_region.Idx_r))),'absorption_f',layer.Frequencies(uui),'load_bar_comp',load_bar_comp);
    
    range_tot=double(trans_obj.get_transceiver_range());
    
    trans_obj.apply_algo('SingleTarget','reg_obj',new_region,'load_bar_comp',load_bar_comp);
    
    if isempty(trans_obj.ST.TS_comp)
        warndlg_perso(main_figure,'','No sphere echoes at all... Try changing your single target detection parameter for this frequency');
        if~isempty(path_out)
            fclose(fid(2));
        end
        continue;
    end
    
    
    [idx_alg,alg_found]=find_algo_idx(trans_obj,'SingleTarget');
    
    
    if alg_found
        varin=trans_obj.Algo(idx_alg).input_params_to_struct();
        max_beam_comp=varin.MaxBeamComp;
    else
        
        max_beam_comp=12;
    end
    
    % When calculating the RMS fit of the data to the Simrad beam pattern, only
    % consider echoes out to (rmsOutTo * beamwidth) degrees.
    
    rmsOutTo = max_beam_comp/12;
    
    cids_up=union({'main','mini'},curr_disp.SecChannelIDs,'stable');
    update_axis(main_figure,0,'main_or_mini',cids_up,'force_update',1);
    display_bottom(main_figure,cids_up);
    clear_regions(main_figure,{},cids_up);
    display_regions(main_figure,cids_up);
    set_alpha_map(main_figure,'main_or_mini',cids_up,'update_bt',0);
    curr_disp.setField('singletarget');
    
    display_tracks(main_figure);
    update_st_tracks_tab(main_figure,'histo',1,'st',1);
    update_environnement_tab(main_figure,0);
    % Optional single target and sphere processing parameters:
    %
    
    % Any sphere echo more than maxDbDiff1 from the theoretical will be
    % discarded as an outlier. Used in a coarse filter prior to actually
    % working out the beam width.
    maxdBDiff1 = 6;
    
    % Beam compensated TS values more than maxdBDiff2 dB above or below the
    % sphere TS are discarded. Done after working out the beam width.
    % Note that this forces an upper limit on the RMS of the final fit to the
    % beam pattern.
    maxdBDiff2 = 1;
    
    % All echoes within onAxisFactor times the beam width will be considered to
    % be on-axis for the purposes of working out the on-axis gain.
    onAxisFactor = 0.015; % [factor]
    
    % If there are less than minOnAxisEchos sphere echoes close to the
    % beam centre (as calculated using onAxisFactor), use
    % onAxisFactorExpanded instead.
    minOnAxisEchoes = 6;
    
    % If insufficient echoes are found with onAxisFactor multiplied by
    % the average of the fore/aft and port/stbd beamwidths,
    % onAxisFactorExpanded will be used instead.
    onAxisFactorExpension = 5; % [factor]
    
    % What method to use when calculating the 'best' estimate of the on-axis
    % sphere TS. Max of on-axis echoes, mean of on-axis echoes, or the peak of
    % the fitted beam pattern.
    onAxisMethod = {'mean','max','beam fitting'};
    
    [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);
      
    % Calculate the mean_ts from echoes that are on-axis
    on_axis = onAxisFactor * mean(faBW + psBW);
    
    AlongAngle_sph = trans_obj.ST.Angle_minor_axis;
    AcrossAngle_sph = trans_obj.ST.Angle_major_axis;
    
    Sp_sph = trans_obj.ST.TS_uncomp;
    %Power_norm = trans_obj.ST.Power_norm;
    
    [phi, ~] = simradAnglesToSpherical(AlongAngle_sph, AcrossAngle_sph);
    
    idx_high=get_highest_target_per_ping(trans_obj.ST);
    
    idx_keep=idx_high&...
        abs(trans_obj.ST.TS_comp-sphere_ts)<=maxdBDiff1&...
        trans_obj.ST.Angle_minor_axis<=faBW*rmsOutTo&...
        trans_obj.ST.Angle_major_axis<=psBW*rmsOutTo;
    
    if nansum(idx_keep)<6
        choice=question_dialog_fig(main_figure,'','It appears that there is no spheres here... Do you want to try and run a calibration anyway?','timeout',10);
        % Handle response
        switch choice
            case 'Yes'
                idx_keep=trans_obj.ST.TS_comp>=-120;
            case 'No'
                if~isempty(path_out)
                    fclose(fid(2));
                end
                continue
        end
    end
    
    if nansum(idx_keep)<6
        warndlg_perso(main_figure,'Not enough sphere echoes','It looks like there is no sphere here...',5);
        continue;
    end
    freq_str=sprintf('%.0f_%s',Freq,layer.ChannelID{uui});
    if idx_freq==uui
        plot(ah,trans_obj.ST.Ping_number(idx_keep),trans_obj.ST.idx_r(idx_keep),'.k','linewidth',2);
    end
    cax=[sphere_ts-12 sphere_ts+3];
    switch trans_obj.Mode
        case 'FM'
            if trans_obj.Config.BeamType>0
                fig_bp=plot_bp(AcrossAngle_sph,AlongAngle_sph,Sp_sph,idx_keep);
                
                if~isempty(path_out)&&~isempty(fig_bp)
                    print(fig_bp,fullfile(path_out,generate_valid_filename(['bp_contour_plot' freq_str '.png'])),'-dpng','-r300');
                end
            else
                peak_ts = prctile(Sp_sph(idx_keep),95);
                idx_keep = idx_keep&abs(Sp_sph-peak_ts)<=maxdBDiff2/2;
            end
            
            
            
        case 'CW'
            [sim_pulse,~]=trans_obj.get_pulse();
            
            Np=length(sim_pulse);
            
            gain=trans_obj.get_current_gain();
            
            % Fit the simrad beam pattern to the data. We get estimated beamwidth,
            % offsets, and peak value from this.
            switch trans_obj.Config.BeamType
                case 0
                    offset_fa = trans_obj.Config.AngleOffsetAlongship;
                    offset_ps = trans_obj.Config.AngleOffsetAthwartship;
                    
                    [faBW,psBW] = trans_obj.get_beamwidth_at_f_c([]);

                    peak_ts = nanmax(Sp_sph(idx_keep));
                    exitflag=1;
                otherwise
                    [offset_fa,faBW,offset_ps,psBW,~,peak_ts,exitflag] = ...
                        fit_beampattern(Sp_sph(idx_keep),AcrossAngle_sph(idx_keep),AlongAngle_sph(idx_keep),maxdBDiff2/2, (faBW+psBW)/2);
            end
            
            % If a beam pattern couldn't be fitted, give up with some diagonistics.
            if exitflag ~= 1
                for ifi=1:length(fid)
                    fprintf(fid(ifi),'Failed to fit the simrad beam pattern to the data.\n');
                    fprintf(fid(ifi),'This probably means that the beampattern is so far from circular\n');
                    fprintf(fid(ifi),'that there is something wrong with the echosounder.\n');
                end
                % Plot the probably wrong data, using the un-filtered dataset
                
                plot_bp(AcrossAngle_sph,AlongAngle_sph,Sp_sph,1:numel(Sp_sph));
                
                if~isempty(path_out)
                    fclose(fid(2));
                end
                continue
            end
            
            % Apply the offsets to the target angles
            AcrossAngle_sph = AcrossAngle_sph - offset_ps;
            AlongAngle_sph = AlongAngle_sph - offset_fa;
            
            [phi, ~] = simradAnglesToSpherical(AlongAngle_sph, AcrossAngle_sph);
            compensation = simradBeamCompensation(faBW, psBW, AlongAngle_sph, AcrossAngle_sph);
            % Filter outliers based on the beam compensated corrected data
            
            
            
            switch trans_obj.Config.BeamType
                case 0
                    idx_keep = idx_keep&abs(Sp_sph+compensation-peak_ts)<=maxdBDiff2/2;
                otherwise
                    idx_keep = idx_keep&abs(Sp_sph+compensation-peak_ts)<=maxdBDiff2;
            end
            
    end
    
    
    idx_keep_sec=idx_keep&abs(phi)<=on_axis;
    if trans_obj.Config.BeamType >0
        if nansum(idx_keep_sec)<minOnAxisEchoes
            warndlg_perso(main_figure,'',sprintf('Less than %d echoes closer than %.1f degrees to the center. Looking out to %.1f degree.',minOnAxisEchoes,on_axis, onAxisFactorExpension*on_axis),5);
            on_axis = onAxisFactorExpension*on_axis;
            idx_keep_sec=idx_keep&abs(phi)<=on_axis;
        end
        
        if nansum(idx_keep_sec)<minOnAxisEchoes
            warndlg_perso(main_figure,'POOR CALIBRATION DATA',sprintf(['Less than %d echoes closer than %.1f degrees to the center. Looking out to %.1f degree.\n'...
                'PRETTY POOR CALIBRATION DATA, I WOULD NOT TRUST IT!!!!'],minOnAxisEchoes,on_axis, onAxisFactorExpension*on_axis),5);
            on_axis = onAxisFactorExpension*on_axis;
            idx_keep_sec=idx_keep&abs(phi)<=on_axis;
        end
        
        if nansum(idx_keep_sec)<minOnAxisEchoes
            warndlg_perso(main_figure,'POOR CALIBRATION DATA',sprintf(['Less than %d echoes closer than %.1f degrees to the center. Looking out to %.1f degree.\n'...
                'You are about to try to obtain a calibration from very poor quality data, with very low number of central echoes...'],minOnAxisEchoes,on_axis, onAxisFactorExpension*on_axis/2),5);
            on_axis = onAxisFactorExpension*on_axis/2;
            idx_keep_sec=idx_keep&abs(phi)<=on_axis;
        end
        
        if nansum(idx_keep_sec)<minOnAxisEchoes
            warndlg_perso(main_figure,'','I have tried very hard and cannot find any usable spere echoes in there... Try changing your single target detection parameter for this frequency');
            if~isempty(path_out)
                fclose(fid(2));
            end
            continue
        end
    else
        if nansum(idx_keep_sec)<minOnAxisEchoes
            warndlg_perso(main_figure,'','Cannot find any usable spere echoes in there for this single-beam calibration... Try changing your single target detection parameter for this frequency');
            if~isempty(path_out)
                fclose(fid(2));
            end
            continue;
        end
        
    end
    if  nansum(idx_keep_sec)<minOnAxisEchoes
        choice=question_dialog_fig(main_figure,'Crappy calibration data detected','Do you want REALLY want to try to calibrate with those crappy data? Well, nothing I can do to stop you them...','timeout',10);
        
        % Handle response
        switch choice
            case 'Yes'
                idx_keep_sec=idx_keep;
            case 'No'
                if ~isempty(path_out)
                    fclose(fid(2));
                end
                continue
        end
    end
    
    r_disp=trans_obj.ST.Target_range();
    r_disp(~idx_keep)=nan;
    % Do a plot of the sphere depth during the calibration
    fig_r=new_echo_figure(main_figure,'Name',sprintf('%.0f kHz: Sphere range',Freq/1e3),'Tag',sprintf('%.0f kHz: Sphere depth',Freq/1e3));
    ax=axes(fig_r,'nextplot','add');
    plot(ax,trans_obj.ST.Ping_number,r_disp);
    axis(ax,'ij');
    box(ax,'on');
    grid(ax,'on');
    title(ax,'Sphere range during the calibration.')
    xlabel(ax,'Ping number')
    ylabel(ax,'Sphere range (m)')
    
    if~isempty(path_out)
        print(fig_r,fullfile(path_out,generate_valid_filename(['sph_depth' freq_str '.png'])),'-dpng','-r300');
    end
    
    
    
    switch trans_obj.Mode
        case 'FM'
            
            idx_peak_tot = trans_obj.ST.idx_r(idx_keep_sec);
            idx_pings = trans_obj.ST.Ping_number(idx_keep_sec);
            
            if isempty(idx_peak_tot)
                warndlg_perso(main_figure,'','Not enough central echoes');
                continue;
            end
            
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(idx_pings), 'Value',0);
            load_bar_comp.progress_bar.setText(sprintf('Processing TS estimation Frequency %.0fkHz',trans_obj.Config.Frequency/1e3));
            
            idx_rem=[];
            f_corr=nan(1,numel(idx_pings));
                       
            cal_struct=trans_obj.get_fm_cal();
            
            for kk=1:length(idx_pings)
                [sp,cp,f,~,f_corr(kk)]=processTS_f_v2(trans_obj,layer.EnvData,idx_pings(kk),range_tot(idx_peak_tot(kk)),cal_struct,att_m);
                if kk==1
                    Sp_f=nan(numel(sp),numel(idx_pings));
                    Compensation_f=nan(numel(sp),numel(idx_pings));
                    f_vec=nan(numel(sp),numel(idx_pings));
                end
                if numel(sp)==size(Sp_f,1)
                    Sp_f(:,kk)=sp;
                    Compensation_f(:,kk)=cp;
                    f_vec(:,kk)=f;
                else
                    idx_rem=union(idx_rem,kk);
                end
                set(load_bar_comp.progress_bar, 'Value',kk);
            end
            
            Sp_f(idx_rem,:)=[];
            Compensation_f(idx_rem,:)=[];
            f_vec(idx_rem,:)=[];
            f_corr(idx_rem)=[];
            freq_vec=f_vec(:,1)';
            
            Compensation_f(Compensation_f>6)=nan;
            
            TS_f=Sp_f+Compensation_f;
            
            TS_f_mean=10*log10(nanmean(10.^(TS_f'/10)));
                        
            th_ts=arrayfun(@(x) spherets(x/c_at_sphere,sph.diameter/2, c_at_sphere, ...
                sph.lont_c, sph.trans_c, density_at_sphere, sph.rho),2*pi*freq_vec);
            
            ts_fig=new_echo_figure(main_figure,'Name','TS','Tag',sprintf('TS%.0f',uui),'Toolbar','esp3','MenuBar','esp3');
            ax=axes(ts_fig,'box','on');
            plot(freq_vec/1e3,TS_f,'linewidth',0.5);
            hold(ax,'on');
            plot(ax,freq_vec/1e3,TS_f_mean,'color',[0.8 0 0],'linewidth',1);
            plot(ax,freq_vec/1e3,th_ts,'k','linewidth',1)
            grid(ax,'on');
            xlabel(ax,'kHz')
            ylabel(ax,'TS(dB)');
            
            if~isempty(path_out)
                print(ts_fig,fullfile(path_out,generate_valid_filename(['ts_f' freq_str '.png'])),'-dpng','-r300');
            end
            
             
            [cal_path,~,~]=fileparts(layer.Filename{1});
            file_cal=fullfile(cal_path,generate_valid_filename(['Calibration_FM_' layer.ChannelID{uui} '.xml']));
            
            
            cal_ts=TS_f_mean;
              
            
            Gf_th=interp1(cal_struct.Frequency,cal_struct.Gain,freq_vec,'linear','extrap'); 
            
            Gf=(cal_ts-th_ts)/2+Gf_th(:)';
            
            save_bool = true;

            qstring=sprintf('Do you want to save those results for frequency %.0f kHz',Freq/1e3);
            choice=question_dialog_fig(main_figure,'Calibration',qstring,'opt',{'Yes' 'No'});
            
        
            switch choice
                case 'No'
                    save_bool = false;
            end
            
            cal_fm.Frequency=freq_vec;
            
            for uif = 1:numel(fields_fm_cal)
                cal_fm.(fields_fm_cal{uif})=interp1(cal_struct.Frequency,cal_struct.(fields_fm_cal{uif}),cal_fm.Frequency,'linear','extrap');
            end
            
            if save_bool
                cal_fm.Gain=Gf(:)';
            else
                cal_fm.Gain=Gf_th(:)';
            end
           
            
            if trans_obj.Config.BeamType == 0
                cal_fm_tot{uui} = cal_fm;
                continue;
            end
            
            qstring=sprintf('Do also want to try and calibrate the Angles for frequency %.0f kHz',Freq/1e3);
            choice=question_dialog_fig(main_figure,'Calibration',qstring,'opt',{'Yes' 'No'});
            
            % Handle response
            switch choice
                case 'No'
                    if save_bool
                        save_cal_to_xml(cal_fm,file_cal);
                    end
                    cal_fm_tot{uui} = cal_fm;
                    continue;
                otherwise
                    
            end
            
            idx_peak_tot = trans_obj.ST.idx_r(idx_keep);
            idx_pings = trans_obj.ST.Ping_number(idx_keep);
    
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(idx_pings), 'Value',0);
            load_bar_comp.progress_bar.setText(sprintf('Processing EQA estimation Frequency %.0fkHz',trans_obj.Config.Frequency/1e3));
            
            idx_rem=[];
            f_corr=nan(1,numel(idx_pings));
            
            for kk=1:length(idx_pings)
                [sp,cp,f,~,f_corr(kk)]=trans_obj.processTS_f_v2(layer.EnvData,idx_pings(kk),range_tot(idx_peak_tot(kk)),cal_fm,att_m);
                if kk==1
                    Sp_f=nan(numel(sp),numel(idx_pings));
                    Compensation_f=nan(numel(sp),numel(idx_pings));
                    f_vec=nan(numel(sp),numel(idx_pings));
                end
                if numel(sp)==size(Sp_f,1)
                    Sp_f(:,kk)=sp;
                    Compensation_f(:,kk)=cp;
                    f_vec(:,kk)=f;
                else
                    idx_rem=union(idx_rem,kk);
                end
                set(load_bar_comp.progress_bar, 'Value',kk);
            end
            
            Sp_f(idx_rem,:)=[];
            
            Compensation_f(idx_rem,:)=[];
            f_vec(idx_rem,:)=[];
            f_corr(idx_rem)=[];
            freq_vec_new=f_vec(:,1);

            BeamWidthAlongship=nan(1,size(f_vec,1));
            BeamWidthAthwartship=nan(1,size(f_vec,1));
            offset_Alongship=nan(1,size(f_vec,1));
            offset_Athwartship=nan(1,size(f_vec,1));
            peak=nan(1,size(f_vec,1));
            exitflag=nan(1,size(f_vec,1));
             
            BeamWidthAlongship_th = interp1(cal_struct.Frequency,cal_struct.BeamWidthAlongship_th,freq_vec_new,int_meth,ext_meth);
            BeamWidthAthwartship_th = interp1(cal_struct.Frequency,cal_struct.BeamWidthAthwartship_th,freq_vec_new,int_meth,ext_meth);
                       
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',size(f_vec,1), 'Value',0);
            load_bar_comp.progress_bar.setText(sprintf('Processing BeamWidth estimation Frequency %.0fkHz',layer.Transceivers(uui).Config.Frequency/1e3));
            
            for tt=1:size(f_vec,1)
                [offset_Alongship(tt), BeamWidthAlongship(tt), offset_Athwartship(tt), BeamWidthAthwartship(tt), ~, peak(tt), exitflag(tt)]...
                    =fit_beampattern(Sp_f(tt,:), AcrossAngle_sph(idx_keep).*f_corr, AlongAngle_sph((idx_keep)).*f_corr,mean([BeamWidthAlongship_th(tt), BeamWidthAthwartship_th(tt)]), mean([BeamWidthAlongship_th(tt), BeamWidthAthwartship_th(tt)]));
                set(load_bar_comp.progress_bar,'Value',tt);
            end
            
            cal_fm.BeamWidthAlongship = interp1(freq_vec_new,BeamWidthAlongship(:)',cal_fm.Frequency,int_meth,ext_meth);
            cal_fm.BeamWidthAthwartship = interp1(freq_vec_new,BeamWidthAthwartship(:)',cal_fm.Frequency,int_meth,ext_meth);

            cal_fm.AngleOffsetAlongship = interp1(freq_vec_new, offset_Alongship(:)',cal_fm.Frequency,int_meth,ext_meth);
            cal_fm.AngleOffsetAthwartship = interp1(freq_vec_new, offset_Athwartship(:)',cal_fm.Frequency,int_meth,ext_meth);
            
            
            b_width_fig=new_echo_figure(main_figure,'Name','BeamWidth','Tag',sprintf('Bwidth%.0f',uui),'Toolbar','esp3','MenuBar','esp3');
            ax=axes(b_width_fig);
            hold(ax,'on');
            plot(ax,cal_fm.Frequency/1e3,cal_fm.BeamWidthAlongship,'color',[0 0.8 0],'linewidth',2);
            plot(ax,cal_struct.Frequency/1e3,cal_struct.BeamWidthAlongship_th,'color',[0 0 0],'linewidth',2);
            plot(ax,cal_fm.Frequency/1e3,cal_fm.BeamWidthAthwartship,'color',[0.8 0 0],'linewidth',2);
            plot(ax,cal_struct.Frequency/1e3,cal_struct.BeamWidthAthwartship_th,'color',[0 0 0.8],'linewidth',2);
            xlabel(ax,'Frequency (kHz)')
            ylabel(ax,'BeamWidth(deg)')
            legend(ax,'Measured Alongship Beamwidth','Theoritical Alongship Beamwidth','Measured Athwardship Beamwidth','Theoritical Athwardship Beamwidth');
            grid(ax,'on');
            drawnow;
            ylim([nanmin(cal_struct.BeamWidthAthwartship_th)*0.7 nanmax(cal_struct.BeamWidthAthwartship_th)*1.3]);
            
            if~isempty(path_out)
                print(b_width_fig,fullfile(path_out,generate_valid_filename(['bw_f_' freq_str '.png'])),'-dpng','-r300');
            end
            

            choice=question_dialog_fig(main_figure,'Calibration',sprintf('Do you want to save those results for frequency %.0f kHz',Freq/1e3));

            % Handle response
            switch choice
                case 'Yes'

                    save_bool = true;
            end
            
            if save_bool
                save_cal_to_xml(cal_fm,file_cal);
            end
            
            cal_fm_tot{uui} = cal_fm;
        case 'CW'
            
            
            ts_values = Sp_sph(idx_keep_sec) + compensation(idx_keep_sec);
            mean_ts_on_axis = 10*log10(mean(10.^(ts_values/10)));
            std_ts_on_axis = std(ts_values);
            max_ts_on_axis = max(ts_values);
            
            % plot up the on-axis TS values
            fig_ts=new_echo_figure(main_figure,'Name', sprintf('%.0f kHz On-axis sphere TS',Freq/1e3),'Tag', sprintf('%.0f kHz On-axis sphere TS',Freq/1e3));
            ax1=axes(fig_ts,'units','normalized','position',[0.05 0.05 0.9 0.4]);
            boxplot(ax1,ts_values);
            ax2=axes(fig_ts,'units','normalized','outerposition',[0.05 0.55 0.9 0.4]);
            histogram(ax2,ts_values);
            xlabel(ax2,'TS (dB re 1 m^2)')
            ylabel(ax1,'TS (dB re 1 m^2)')
            title(ax2,['On axis TS values for ' num2str(numel(ts_values)) ' targets']);
            
            if~isempty(path_out)
                print(fig_ts,fullfile(path_out,generate_valid_filename(['on_axis_ts' freq_str '.png'])),'-dpng','-r300');
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Produce plots and output text
            
            % The calibration results
            oa = num2str(on_axis);
            for ifi=1:length(fid)
                fprintf(fid(ifi),['\nMean ts within ' oa ' deg of centre = ' num2str(mean_ts_on_axis) ' dB\n']);
                fprintf(fid(ifi),['Std of ts within ' oa ' deg of centre = ' num2str(std_ts_on_axis) ' dB\n']);
                fprintf(fid(ifi),['Maximum TS within ' oa ' deg of centre = ' num2str(max_ts_on_axis) ' dB\n']);
                fprintf(fid(ifi),['Number of echoes within ' oa ' deg of centre = ' num2str(numel(ts_values)) '\n']);
                fprintf(fid(ifi),['On axis TS from beam fitting = ' num2str(peak_ts) ' dB\n']);
                fprintf(fid(ifi),['The sphere ts is ' num2str(sphere_ts) ' dB\n']);
            end
            old_cal=trans_obj.get_cal();
            outby=nan(1,length(onAxisMethod));
            for k=1:length(onAxisMethod)
                if strcmp(onAxisMethod{k}, 'max')
                    outby(k) = sphere_ts - max_ts_on_axis;
                elseif strcmp(onAxisMethod{k}, 'mean')
                    outby(k) = sphere_ts - mean_ts_on_axis;
                elseif strcmp(onAxisMethod{k}, 'beam fitting')
                    outby(k) = sphere_ts - peak_ts;
                end
                for ifi=1:length(fid)
                    if outby(k) > 0
                        fprintf(fid(ifi),['Hence Ex60 is reading ' num2str(outby(k)) ' dB too low (' onAxisMethod{k} ' method)\n']);
                    else
                        fprintf(fid(ifi),['Hence Ex60 is reading ' num2str(abs(outby(k))) ' dB too high (' onAxisMethod{k} ' method)\n']);
                    end
                    fprintf(fid(ifi),['So add ' num2str(-outby(k)/2) ' dB to G_o (' onAxisMethod{k} ' method)\n']);
                    fprintf(fid(ifi),['G_o from .raw file is ' num2str(gain) ' dB\n']);
                    fprintf(fid(ifi),['So the calibrated G_o = ' num2str(old_cal.G0-outby(k)/2) ' dB (' onAxisMethod{k} ' method)\n']);
                end
            end
            for ifi=1:length(fid)
                fprintf(fid(ifi),['Mean sphere range = ' num2str(mean(trans_obj.ST.Target_range(idx_keep_sec))) ...
                    ' m, std = ' num2str(std(trans_obj.ST.Target_range(idx_keep_sec))) ' m\n']);
            end
            
            if trans_obj.Config.BeamType>0
                fig_bp=plot_bp(AcrossAngle_sph,AlongAngle_sph,Sp_sph+outby(1),idx_keep);
                if~isempty(path_out)&&~isempty(fig_bp)
                    print(fig_bp,fullfile(path_out,generate_valid_filename(['bp_contour_plot' freq_str '.png'])),'-dpng','-r300');
                end
                
                % Do a plot of the compensated and uncompensated echoes at a selection of
                % angles, similar to what one can get from the Simrad calibration program
                
                fig=plotBeamSlices(AcrossAngle_sph(idx_keep),AlongAngle_sph(idx_keep),Sp_sph(idx_keep),outby(1),(faBW + psBW)/2, faBW, psBW, peak_ts, 1/2);
                
                if~isempty(path_out)&&~isempty(fig)
                    print(fig,fullfile(path_out,generate_valid_filename(['slices' freq_str '.png'])),'-dpng','-r300');
                end
            end
            % The Sa correction is a value that corrects for the received pulse having
            % less energy in it than that nominal, transmitted pulse. The formula for
            % Sv  includes a term -10log10(Teff) (where Teff is the
            % effective pulse length). We don't have Teff, so need to calculate it. We
            % do have Tnom (the nominal pulse length) and just need to scale Tnom so
            % that it gives the same result as the integral of Teff:
            %
            % Teff = Tnom * alpha_corr
            % alpha_corr = Teff / Tnom
            % alpha_corr = Int(dt) / (Pmax * Tnom)
            %  where P is the power measurements throughout the echo,
            %  Pmax is the max power in the echo, and dt the time
            %  between P measurements. This is simply the ratio of the area under the
            %  nominal pulse and the area under the actual pulse.
            %
            % For the EK60/80, dt = Tnom/Np (it samples Np times every pulse length)
            % So, alpha_corr = Sum(P * Tnom) / (Np * Pmax * Tnom)
            %     alpha_corr = Sum(P) / (Np * Pmax)
            %
            % Correction factor is excpected to be in dB, and
            % furthermore is used as (10log10(Tnom) + 2 * Sa). Hence
            % Sa = 0.5 * 10log10(alpha_corr)
            
            % Work in the linear domain to calculate the scale factor to convert the
            % nominal pulse length into the effective pulse length
            
            sig_pulse=zeros(1,2*Np);
            sig_pulse(1+floor(Np/2):floor(Np/2)+Np)=sim_pulse(:)';
            %alpha_new = mean(Power_norm(idx_keep_sec))/nansum(abs(sim_pulse).^2);
            
            st_sig_tmp=trans_obj.get_st_sig('power');
            idx_keep_sec=idx_keep_sec&cellfun(@numel,st_sig_tmp)==2*Np;
            
            norm_pow=cellfun(@(x) x/max(x),st_sig_tmp(idx_keep_sec),'un',0);
            sum_pow=cellfun(@sum,norm_pow);
            
            alpha_corr = mean(sum_pow)/nansum(abs(sim_pulse).^2);
            % And convert that to dB, taking account of how this ratio is used as 2Sa
            % everywhere (i.e., it needs to be halved after converting to dB).
            
            sa_correction = 5 * log10(alpha_corr);
            %sa_correction_new = 5 * log10(alpha_new);
            
            
            ff=new_echo_figure(main_figure,'Name',sprintf('%.0f kHz: Pulse Comparison',Freq/1e3),'Tag',sprintf('%.0f kHz: Pulse Comparison',Freq/1e3));
            ax=axes(ff,'nextplot','add');
            cellfun(@(x) plot(x),norm_pow);
            plot(ax,abs(sig_pulse),'r','linewidth',2);
            grid(ax,'on');
            xlabel(ax,'Sample Number');
            ylabel(ax,'Normalized Power');
            
            % Calculate the RMS fit to the beam model
            fit_out_to = rmsOutTo * (faBW+psBW)/2; % fit out to rmsOutTo of the beamangle
            id = find(phi <= fit_out_to & idx_keep);
            beam_model = peak_ts - compensation;
            rms_fit = sqrt( mean( ( (Sp_sph(id) - beam_model(id))/2 ).^2 ) );
            
            cal_cw.SACORRECT(uui)=sa_correction;
            cal_cw.G0(uui)=old_cal.G0-outby(strcmp(onAxisMethod,'mean'))/2;
            
            cal_cw.AngleOffsetAlongship(uui)=offset_fa-trans_obj.Config.AngleOffsetAlongship;
            cal_cw.AngleOffsetAthwartship(uui)=offset_ps-trans_obj.Config.AngleOffsetAthwartship;
            cal_cw.BeamWidthAlongship(uui)=faBW;
            cal_cw.BeamWidthAthwartship(uui)=psBW;
            cal_cw.EQA(uui)=10*log10(2.2578*sind(cal_cw.BeamWidthAlongship(uui)/4+cal_cw.BeamWidthAthwartship(uui)/4).^2);
            cal_cw.RMS(uui)=rms_fit;
            
            for ifi=1:length(fid)
                % Print out some more cal results
                fprintf(fid(ifi),['So sa correction = ' num2str(sa_correction) ' dB\n']);
                fprintf(fid(ifi),['(the effective pulse length = ' num2str(alpha_corr) ' * nominal pulse length\n']);
                
                fprintf(fid(ifi),['Fore/aft beamwidth = ' num2str(faBW) ' degrees\n']);
                fprintf(fid(ifi),['Fore/aft offset = ' num2str(offset_fa-trans_obj.Config.AngleOffsetAlongship) ' degrees (to be subtracted from angles)\n']);
                fprintf(fid(ifi),['Port/stbd beamwidth = ' num2str(psBW) ' degrees\n']);
                fprintf(fid(ifi),['Port/stbd offset = ' num2str(offset_ps-trans_obj.Config.AngleOffsetAthwartship) ' degrees (to be subtracted from angles)\n']);
                fprintf(fid(ifi),['Results obtained from ' num2str(numel(Sp_sph(id))) ' sphere echoes\n']);
                fprintf(fid(ifi),['Using c = ' num2str(layer.EnvData.SoundSpeed) ' m/s\n']);
                fprintf(fid(ifi),['Using alpha = ' num2str(trans_obj.Alpha(1)*1e3) ' dB/km\n']);
                fprintf(fid(ifi),['RMS of fit to beam model out to ' num2str(fit_out_to) ' degrees = ' num2str(rms_fit) ' dB\n']);
            end
            
            if~isempty(path_out)
                fclose(fid(2));
            end
            
            
            
    end
end

hide_status_bar(main_figure);
loadEcho(main_figure);


    function bpfig=plot_bp(ac_a, al_a, sp,idx_keep)
        
        [xg,yg]=meshgrid(-psBW:.1:psBW,...
            -faBW:.1:faBW);
        
        c=nanmin(sp(:)):1:nanmax(sp(:));
        
        zg = griddata(ac_a(idx_keep), al_a(idx_keep), sp(idx_keep), xg, yg);
        
        bpfig=new_echo_figure(main_figure,'Name',sprintf('%.0f kHz Beam Pattern',Freq/1e3),'Tag',sprintf('Bp%.0f',uui),'Toolbar','esp3','MenuBar','esp3');
        ax_bp=axes(bpfig,'nextplot','add','outerposition',[0 0 0.5 1],'box','on');
        contourf(ax_bp,xg,yg,zg,c)
        hold(ax_bp,'on');
        plot(ax_bp,ac_a(idx_keep),al_a(idx_keep),'+','MarkerSize',1,'MarkerEdgeColor',[.5 .5 .5])
        axis(ax_bp,'equal')
        grid(ax_bp,'on');
        colormap(ax_bp,cmap)
        shading(ax_bp,'flat');
        xlabel(ax_bp,'Port/stbd angle (\circ)')
        ylabel(ax_bp,'Fore/aft angle (\circ)')
        title(ax_bp,sprintf('%.0f kHz',Freq/1e3))
        caxis(ax_bp,cax)
        
        for r_p = 2:4
            x = psBW/r_p * cos(0:.01:2*pi);
            y = faBW/r_p * sin(0:.01:2*pi);
            plot(ax_bp,x, y, 'k')
        end
        
        comp = simradBeamCompensation(faBW, psBW, al_a, ac_a);
        
        zg_comp = griddata(ac_a(idx_keep), al_a(idx_keep), sp(idx_keep)+comp(idx_keep), xg, yg);
        
        ax_bp=axes(bpfig,'nextplot','add','outerposition',[0.5 0 0.5 1],'box','on');
        surf(ax_bp,xg,yg, zg)
        surf(ax_bp,xg,yg, zg_comp)
        axis(ax_bp,'equal');
        grid(ax_bp,'on');
        colormap(ax_bp,cmap)
        shading(ax_bp,'flat');
        cb=colorbar(ax_bp);
        cb.UIContextMenu=[];
        xlabel(ax_bp,'Port/stbd angle (\circ)')
        ylabel(ax_bp,'Fore/aft angle (\circ)')
        zlabel(ax_bp,'TS (dB re 1m^2)')
        title(ax_bp,sprintf('%.0f kHz',Freq/1e3))
        caxis(ax_bp,cax)
        view(ax_bp,[-37.5 30]);
        drawnow;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function fig_out=plotBeamSlices(ac_a, al_a, sp, outby, trimTo, faBW, psBW, peak_ts, tol)
        % Produce a plot of the sphere echoes and the fitted beam pattern at 4
        % slices (0 45, 90, and 135 degrees) through the beam.
        %
        
        fig_out=new_echo_figure(main_figure,'Name',sprintf('%.0f kHz: Beam slice plot',Freq/1e3),'Tag',sprintf('%.0f kHz: Beam slice plot',Freq/1e3));
        x = -trimTo:.1:trimTo;
        
        % 0 degrees
        ax_1=axes(fig_out,'position',[0.05 0.55 0.4 0.4],'nextplot','add');
        id = find(abs(ac_a) < tol);
        plot(ax_1,al_a(id), sp(id)+ outby(1),'k.')
        
        plot(ax_1,x, peak_ts+ outby(1)  - simradBeamCompensation(faBW, psBW, x, 0), 'k');
        
        % 45 degrees. Needs special treatment to get angle off axis from the fa and
        % ps angles
        ax_2=axes(fig_out,'position',[0.55 0.55 0.4 0.4],'nextplot','add');
        id = find(abs(ac_a - al_a) < tol);
        [phi_x,~] = simradAnglesToSpherical(al_a(id), ac_a(id));
        ss = sp(id) + outby(1);
        
        id = find(abs(phi_x) <= trimTo);
        plot(ax_2,phi_x(id), ss(id), 'k.')
        
        [phi_x,~] = simradAnglesToSpherical(x, x);
        beam = peak_ts+ outby(1) - simradBeamCompensation(faBW, psBW, x, x);
        id = find(abs(phi_x) <= trimTo);
        plot(ax_2,phi_x(id), beam(id), 'k');
        
        % 90 degrees
        ax_3=axes(fig_out,'position',[0.05 0.1 0.4 0.4],'nextplot','add');
        id = find(abs(al_a) < tol);
        plot(ax_3,ac_a(id), sp(id)+ outby(1),'k.')
        
        plot(ax_3,x, peak_ts + outby(1) - simradBeamCompensation(faBW, psBW, 0, x), 'k');
        xlabel(ax_3,'Angle (\circ) off normal')
        ylabel(ax_3,'TS (dB re 1m^2)')
        
        % 135 degrees. Needs special treatment to get angle off axis from the fa and
        % ps angles
        ax_4=axes(fig_out,'position',[0.55 0.1 0.4 0.4],'nextplot','add');
        id = find(abs(-ac_a - al_a) < tol);
        [phi_x,~] = simradAnglesToSpherical(al_a(id), ac_a(id));
        ss = sp(id) + outby(1);
        id = find(abs(phi_x) <= trimTo);
        plot(ax_4,phi_x(id), ss(id),'k.')
        
        [phi_x,~] = simradAnglesToSpherical(-x, x);
        beam = peak_ts + outby(1) - simradBeamCompensation(faBW, psBW, -x, x);
        id = find(abs(phi_x) <= trimTo);
        plot(ax_4,phi_x(id), beam(id), 'k');
        ax_t=[ax_1 ax_2 ax_3 ax_4];
        
        % Make the y-axis limits the same for all 4 subplots
        limits = [1000 -1000 1000 -1000];
        for it = 1:4
            lim = axis(ax_t(it));
            limits(1) = min(limits(1), lim(1));
            limits(2) = max(limits(2), lim(2));
            limits(3) = min(limits(3), lim(3));
            limits(4) = max(limits(4), lim(4));
        end
        
        % Expand the axis limits so that axis labels don't overlap
        limits(1) = limits(1) - .2; % x-axis, units of degrees
        limits(2) = limits(2) + .2; % x-axis, units of degrees
        limits(3) = limits(3) - 1; % y-axis, units of dB
        limits(4) = limits(4) + 1; % y-axis, units of dB
        for it = 1:4
            axis(ax_t(it),limits)
        end
        
        % Add a line to each subplot to indicate which angle the slice is for.
        % Work out the position for the ship schematic with angled line.
        angles = [0 45 90 135]; % angles of the four plots
        for it = 1:length(angles)
            pos = get(ax_t(it), 'Position');
            ax_b=axes('Position', [pos(1)+0.02*pos(3) pos(2)+0.7*pos(4) 0.2*pos(3) 0.2*pos(4)],'nextplot','add');
            plot_angle_diagram(angles(it),ax_b)
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plot_angle_diagram(angle,ax_b)
        % Plots a little figure of the ship and an angled line on the given axes
        
        % The ship shape
        x = [0 1 1 .5 0 0];
        y = [0 0 2 2.5 2 0];
        plot(ax_b,x,y,'k')
        
        % The circle to represent the transducer
        theta = 0:.01:2.1*pi;
        r = 0.3;
        centre = [0.5 1.5];
        ll = 0.9;
        plot(ax_b,centre(1) + r*cos(theta), centre(2) + r*sin(theta), 'k')
        
        % The angled line
        switch angle
            case 0
                plot(ax_b,[centre(1) centre(1)], [centre(2)-ll centre(2)+ll], 'k', 'LineWidth', 2)
            case 45
                x = ll*cos(angle*pi/180);
                y = ll*sin(angle*pi/180);
                plot(ax_b,[centre(1)-x centre(1)+x] ,[centre(2)-y centre(2)+y], 'k', 'LineWidth', 2)
            case 90
                plot(ax_b,[centre(1)-ll centre(1)+ll], [centre(2) centre(2)], 'k', 'LineWidth', 2)
            case 135
                x = ll*cos(angle*pi/180);
                y = ll*sin(angle*pi/180);
                plot(ax_b,[centre(1)+x centre(1)-x] ,[centre(2)+y centre(2)-y], 'k', 'LineWidth', 2)
        end
        
        axis(ax_b,'equal');
        
        % The bottom of some figures get chopped off when removing the axis, so
        % extend the axis a little to prevent this
        set(ax_b, 'YLim', [-0.1 2.6])
        axis(ax_b,'off')
        
    end

    function idx_high=get_highest_target_per_ping(ST)
        pings=unique(ST.Ping_number);
        idx_high=zeros(size(ST.Ping_number));
        for uip=1:numel(pings)
            id_p = find(pings(uip) == ST.Ping_number);
            
            [~,id_max] = nanmax(ST.TS_uncomp(id_p));
            idx_high(id_p(id_max))=1;
        end
    end

end
