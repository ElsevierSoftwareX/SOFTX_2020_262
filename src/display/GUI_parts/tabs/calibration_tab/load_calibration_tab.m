function load_calibration_tab(main_figure,option_tab_panel)

if isappdata(main_figure,'Calibration_tab')
    calibration_tab_comp=getappdata(main_figure,'Calibration_tab');
    delete(get(calibration_tab_comp.calibration_tab,'children'));
else
    calibration_tab_comp.calibration_tab=uitab(option_tab_panel,'Title','Calibration','tag','cal');
end

curr_disp=get_esp3_prop('curr_disp');

gui_fmt=init_gui_fmt_struct();

pos=create_pos_3(7,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
p_button=pos{6,1}{1};
p_button(3)=gui_fmt.button_w*7/4;


calibration_tab_comp.cal_group=uipanel(calibration_tab_comp.calibration_tab,'Position',[0 0.0 0.3 1],'title','','units','norm','BackgroundColor','white');

calibration_tab_comp.calibration_txt=uicontrol(calibration_tab_comp.cal_group,gui_fmt.txtTitleStyle,...
    'String',sprintf('Current Channel: %.0f kHz',curr_disp.Freq/1e3),'Position',pos{1,1}{1}+[0 0 gui_fmt.txt_w 0]);

uicontrol(calibration_tab_comp.cal_group,gui_fmt.txtStyle,'String','Gain (dB)','Position',pos{2,1}{1});
calibration_tab_comp.G0=uicontrol(calibration_tab_comp.cal_group,gui_fmt.edtStyle,'position',pos{2,1}{2},'string','25.00','callback',{@apply_calibration,main_figure},'enable','off');

uicontrol(calibration_tab_comp.cal_group,gui_fmt.txtStyle,'String','EQA (dB)','Position',pos{4,1}{1});
calibration_tab_comp.EQA=uicontrol(calibration_tab_comp.cal_group,gui_fmt.edtStyle,'position',pos{4,1}{2},'string','-26.00','callback',{@apply_calibration,main_figure},'enable','off');

uicontrol(calibration_tab_comp.cal_group,gui_fmt.txtStyle,'String','Sa Corr (dB)','Position',pos{3,1}{1});
calibration_tab_comp.SACORRECT=uicontrol(calibration_tab_comp.cal_group,gui_fmt.edtStyle,'position',pos{3,1}{2},'string','0.00','callback',{@apply_calibration,main_figure},'enable','off');

%         uicontrol(calibration_tab_comp.cal_group,gui_fmt.txtStyle,'String','ES Corr (dB)','Position',pos{4,1}{1});
%         calibration_tab_comp.EsOffset=uicontrol(calibration_tab_comp.cal_group,gui_fmt.edtStyle,'position',pos{4,1}{2},'string',num2str(trans_obj.Config.EsOffset,'%.2f'),'callback',{@apply_triangle_wave_corr_cback,main_figure});
%
%         if trans_obj.need_escorr()==0
%             set(calibration_tab_comp.EsOffset,'Enable','off');
%         end

uicontrol(calibration_tab_comp.cal_group,gui_fmt.pushbtnStyle,'String','Process TS Cal','callback',{@reprocess_TS_calibration,main_figure},'position',p_button);
calibration_tab_comp.cw_proc(1)=uicontrol(calibration_tab_comp.cal_group,gui_fmt.pushbtnStyle,'String','Save CW  Cal','callback',{@save_CW_calibration,main_figure},'position',p_button+[0 -gui_fmt.box_h 0 0]);
calibration_tab_comp.fm_proc(1)=uicontrol(calibration_tab_comp.cal_group,gui_fmt.pushbtnStyle,'String','Disp.Cal.','callback',{@display_cal,main_figure},'position',p_button+[p_button(3) -gui_fmt.box_h 0 0]);

uicontrol(calibration_tab_comp.cal_group,gui_fmt.txtStyle,'string','Sphere:','position',pos{5,1}{1});
sphere_struct=list_spheres();
calibration_tab_comp.sphere=uicontrol(calibration_tab_comp.cal_group,gui_fmt.popumenuStyle,'string',{sphere_struct(:).name},'position',pos{5,1}{2}+[0 0 gui_fmt.txt_w/2 0]);

calibration_tab_comp.ax_group=uipanel(calibration_tab_comp.calibration_tab,'Position',[0.3 0.0 0.7 1],'title','','units','norm','BackgroundColor','white');

field={'EQA','SACORRECT','G0'};
label={'EQA (dB)','Sa_{corr} (dB)','G0 (dB)'};
y_sep=0.0  ;
ll=(0.85-(numel(field))*y_sep)/numel(field);
for iax=1:numel(field)
    calibration_tab_comp.(['ax_' field{iax}])=axes(calibration_tab_comp.ax_group,...
        'Interactions',[],...
        'Toolbar',[],...
        'Units','Normalized',...
        'nextplot','add',...
        'YlimMode','auto',...
        'Position',[0.075 0.15+(iax-1)*(ll+y_sep) 0.85 ll],...
        'XGrid','on','YGrid','on','box','on','XMinorGrid','off','tag',field{iax},...
        'XAxisLocation','bottom');
    if iax>1
        set(calibration_tab_comp.(['ax_' field{iax}]),'XTickLabel',{});
    else
        calibration_tab_comp.(['ax_' field{iax}]).XAxis.TickLabelFormat='%.0fkHz';
        calibration_tab_comp.(['ax_' field{iax}]).XAxis.TickLabelRotation=30;
    end
    ylabel(calibration_tab_comp.(['ax_' field{iax}]),label{iax})
    rm_axes_interactions(calibration_tab_comp.(['ax_' field{iax}]));
end

calibration_tab_comp.l_prop=linkprop([calibration_tab_comp.ax_EQA calibration_tab_comp.ax_G0 calibration_tab_comp.ax_SACORRECT],{'XTick' 'XLim'});

setappdata(main_figure,'Calibration_tab',calibration_tab_comp);


end


function reprocess_TS_calibration(~,~,main_figure)
layer=get_current_layer();
if ~isempty(layer)
    TS_calibration_curves_func(main_figure,layer,[]);
end
update_calibration_tab(main_figure);
end




function apply_calibration(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
if ~isempty(layer)
    calibration_tab_comp=getappdata(main_figure,'Calibration_tab');
    
    [trans_obj,~]=layer.get_trans(curr_disp);
    
    
    old_cal=trans_obj.get_cal();
    
    if ~isnan(str2double(get(calibration_tab_comp.G0,'string')))
        new_cal.G0=str2double(get(calibration_tab_comp.G0,'string'));
    else
        new_cal.G0=old_cal.G0;
    end
    
    if ~isnan(str2double(get(calibration_tab_comp.SACORRECT,'string')))
        new_cal.SACORRECT=str2double(get(calibration_tab_comp.SACORRECT,'string'));
    else
        new_cal.SACORRECT=old_cal.SACORRECT;
    end
    
    if ~isnan(str2double(get(calibration_tab_comp.EQA,'string')))
        new_cal.EQA=str2double(get(calibration_tab_comp.EQA,'string'));
    else
        new_cal.EQA=old_cal.EQA;
    end
    
    trans_obj.apply_cw_cal(new_cal);
    update_calibration_tab(main_figure);
    
    
    update_axis(main_figure,0,'main_or_mini',union({'main','mini'},curr_disp.ChannelID,'stable'),'force_update',1);
    set_alpha_map(main_figure,'update_bt',0);
    
end
end



function save_CW_calibration(~,~,main_figure)
apply_calibration([],[],main_figure);
layer=get_current_layer();
if ~isempty(layer)
    try
        cal_cw=extract_cal_to_apply(layer,layer.get_cal());
    catch err
        print_errors_and_warnings([],'error',err);
        disp_perso(main_figure,'Could not read calibration file');
        cal_cw=get_cal(layer);
    end
    [cal_path,~,~]=fileparts(layer.Filename{1});
    
    
    cal_file=fullfile(cal_path,'cal_echo.csv');
    cal_f=init_cal_struct(cal_file);
    if ~isempty(cal_f)
        idx_add=find(~ismember(cal_f.CID,cal_cw.CID));
    else
        idx_add=[];
    end
    fid=fopen(cal_file,'w');
    
    fprintf(fid,'%s,%s,%s,%s,%s,%s\n', 'FREQ', 'CID','G0', 'SACORRECT','EQA','alpha');
    for i=1:length(cal_cw.G0)
        fprintf(fid,'%.0f,%s,%.2f,%.2f,%.2f,%.2f\n',cal_cw.FREQ(i),cal_cw.CID{i},cal_cw.G0(i),cal_cw.SACORRECT(i),cal_cw.EQA(i),cal_cw.alpha(i));
    end
    
    for i=idx_add'
        fprintf(fid,'%.0f,%s,%.2f,%.2f,%.2f,%.2f\n',cal_f.FREQ(i),cal_f.CID{i},cal_f.G0(i),cal_f.SACORRECT(i),cal_f.EQA(i),cal_f.alpha(i));
    end
    
    fclose(fid);
end
end
