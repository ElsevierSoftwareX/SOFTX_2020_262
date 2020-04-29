function xml_scrip_fig=create_xml_script_gui(varargin)

p = inputParser;
default_absorption=[2.7 9.8 22.8 37.4 52.7];
default_absorption_f=[18000 38000 70000 120000 200000];

addParameter(p,'main_figure',[],@(x)isempty(x)||ishandle(x));
addParameter(p,'survey_input_obj',survey_input_cl(),@(x) isa(x,'survey_input_cl'));
addParameter(p,'existing_scripts',0,@isnumeric);
addParameter(p,'logbook_file','',@(x) isfile(x)||isfolder(x));


parse(p,varargin{:});
size_max = get(0,'ScreenSize');
use_defaults=1;

survey_input_obj=p.Results.survey_input_obj;
cal=[];
if ~isempty(p.Results.main_figure)
    layers=get_esp3_prop('layers');
    if ~isempty(layers)
        [files_open,lay_IDs]=layers.list_files_layers();
        [folds,~,~]=cellfun(@fileparts,files_open,'un',0);
        if isfile(p.Results.logbook_file())
            path_f=fileparts(p.Results.logbook_file);
        else
            path_f=p.Results.logbook_file;
        end
        idx_f=find(strcmpi(folds,path_f));
        if ~isempty(idx_f)
            lay_id=lay_IDs{idx_f(1)};
            idx_lay=find(strcmpi({layers(:).Unique_ID},lay_id));
            if~ isempty(idx_f)
                use_defaults=0;
                cal=layers(idx_lay).get_cal();
                
            end
        end
    end
end


if use_defaults
    if p.Results.existing_scripts==0
        cal.FREQ=default_absorption_f;
        cal.CID=cell(size(default_absorption_f));
        cal.alpha=default_absorption;
        cal.G0=25*ones(size(cal.FREQ));
        cal.EQA=-21*ones(size(cal.FREQ));
        cal.SACORRECT=zeros(size(cal.FREQ));
        str_box='No layers from the trip you are trying to build a script on are currently open, it will not know which Frequencies and calibration parameters to initialize.';
        disp_done_figure(p.Results.main_figure,str_box);
    end

end

if isempty(cal)
    cal.FREQ=union(survey_input_obj.Options.Frequency,survey_input_obj.Options.FrequenciesToLoad);
    for i=1:numel(cal.FREQ)
        if cal.FREQ<120000
            att_model='doonan';
        else
            att_model='fandg';
        end
        cal.alpha(i)=seawater_absorption(cal.FREQ(i)/1e3,35,18, 20,att_model);
        cal.G0(i)=25;
        cal.SACORRECT(i)=0;
        cal.EQA(i)=-21;
        cal.CID{i}='';
    end
end

if p.Results.existing_scripts==0
    survey_input_obj.Options.FrequenciesToLoad=cal.FREQ;
    if ismember(survey_input_obj.Options.Frequency,survey_input_obj.Options.FrequenciesToLoad)
        survey_input_obj.Options.Frequency=cal.FREQ(survey_input_obj.Options.Frequency==survey_input_obj.Options.FrequenciesToLoad);
    else
        survey_input_obj.Options.Frequency=cal.FREQ(1);
    end
end

if p.Results.existing_scripts==0
    if ~isempty(survey_input_obj.Cal)
        [idx_f,idx_c]=ismember(cal.FREQ,[survey_input_obj.Cal(:).FREQ]);
        idx_c(idx_c==0)=[];
        if any(idx_f)
            cal.FREQ(idx_f)=[survey_input_obj.Cal(idx_c).FREQ];
            cal.G0(idx_f)=[survey_input_obj.Cal(idx_c).G0];
            cal.SACORRECT(idx_f)=[survey_input_obj.Cal(idx_c).SACORRECT];
            cal.EQA(idx_f)=[survey_input_obj.Cal(idx_c).EQA];
            cal.CID(idx_f)=[survey_input_obj.Cal(idx_c).CID];
        end
    end
end

survey_input_obj.Options.Absorption=cal.alpha;

surv_opt_obj=survey_input_obj.Options;

if ~isdeployed()
    ws='normal';
else
    ws='modal';
end

xml_scrip_fig=new_echo_figure(p.Results.main_figure,'WindowStyle',ws,'Resize','on','Position',[0 0 size_max(3)*0.8 size_max(4)*0.8],...
    'Name','Script Builder','visible','off','Tag','XMLScriptCreationTool');

%pos_main=getpixelposition(xml_scrip_fig);

xml_scrip_h.infos_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[0 3/5 1/3 2/5],'title','(1) Information','BackgroundColor','white','fontweight','bold');
xml_scrip_h.options_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[0 0 1/3 3/5],'title','(2) Echo-Integrations settings','BackgroundColor','white','fontweight','bold');
xml_scrip_h.cal_f_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 3/4 1/3 1/4],'title','(3) Frequencies/Calibration/Absorption','BackgroundColor','white','fontweight','bold');
xml_scrip_h.regions_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 3/4-1/3 1/3 1/3],'title','(4) Regions','BackgroundColor','white','fontweight','bold');
xml_scrip_h.algos_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 1/6 1/3 1/4],'title','(5) Algorithms','BackgroundColor','white','fontweight','bold');
xml_scrip_h.validation_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[1/3 0 1/3 1/6],'title','(7) Create Script','BackgroundColor','white','fontweight','bold');
xml_scrip_h.transect_panel=uipanel(xml_scrip_fig,'units','normalized','Position',[2/3 0 1/3 1],'title','(6) Select transects','BackgroundColor','white','fontweight','bold');

% default_info=struct('Script','','XmlId','','Title','','Main_species','','Areas','','Voyage','','SurveyName','',...
%     'Author','','Created','','Comments','');
gui_fmt=init_gui_fmt_struct('norm',11,1);
tmp=gui_fmt.box_w;
gui_fmt.box_w=gui_fmt.txt_w*0.9;
gui_fmt.txt_w=tmp;

pos=create_pos_3(11,1,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);


uicontrol(xml_scrip_h.infos_panel,gui_fmt.txtStyle,'Position',pos{1,1}{1},'String','Title:');
xml_scrip_h.Infos.Title=uicontrol(xml_scrip_h.infos_panel,gui_fmt.edtStyle,'Position',pos{1,1}{2},'String',survey_input_obj.Infos.Title,'Tag','Title');

uicontrol(xml_scrip_h.infos_panel,gui_fmt.txtStyle,'Position',pos{2,1}{1},'String','Voyage:');
xml_scrip_h.Infos.Voyage=uicontrol(xml_scrip_h.infos_panel,gui_fmt.edtStyle,'Position',pos{2,1}{2},'String',survey_input_obj.Infos.Voyage,'Tag','Voyage');

uicontrol(xml_scrip_h.infos_panel,gui_fmt.txtStyle,'Position',pos{3,1}{1},'String','Survey Name:');
xml_scrip_h.Infos.SurveyName=uicontrol(xml_scrip_h.infos_panel,gui_fmt.edtStyle,'Position',pos{3,1}{2},'String',survey_input_obj.Infos.SurveyName,'Tag','SurveyName');

uicontrol(xml_scrip_h.infos_panel,gui_fmt.txtStyle,'Position',pos{4,1}{1},'String','Areas:');
xml_scrip_h.Infos.Areas=uicontrol(xml_scrip_h.infos_panel,gui_fmt.edtStyle,'Position',pos{4,1}{2},'String',survey_input_obj.Infos.Areas,'Tag','Areas');

uicontrol(xml_scrip_h.infos_panel,gui_fmt.txtStyle,'Position',pos{5,1}{1},'String','Main Species:');
xml_scrip_h.Infos.Main_species=uicontrol(xml_scrip_h.infos_panel,gui_fmt.edtStyle,'Position',pos{5,1}{2},'String',survey_input_obj.Infos.Main_species,'Tag','Main_species');

uicontrol(xml_scrip_h.infos_panel,gui_fmt.txtStyle,'Position',pos{6,1}{1},'String','Author:');
xml_scrip_h.Infos.Author=uicontrol(xml_scrip_h.infos_panel,gui_fmt.edtStyle,'Position',pos{6,1}{2},'String',survey_input_obj.Infos.Author,'Tag','Author');

uicontrol(xml_scrip_h.infos_panel,gui_fmt.txtStyle,'Position',pos{7,1}{1},'String','Comments:');
xml_scrip_h.Infos.Comments=uicontrol(xml_scrip_h.infos_panel,gui_fmt.edtStyle,'Position',pos{11,1}{2}+[-pos{1,1}{1}(3)  0 pos{1,1}{1}(3) 4*pos{1,1}{1}(4)],...
    'String',survey_input_obj.Infos.Comments,'Tag','Comments','Min',0,'Max',10);

fields=fieldnames(xml_scrip_h.Infos);

for ifi=1:numel(fields)
    set(xml_scrip_h.Infos.(fields{ifi}),'Callback',{@update_survey_input_infos,fields{ifi}});
    switch xml_scrip_h.Infos.(fields{ifi}).Style
        case 'edit'
               set(xml_scrip_h.Infos.(fields{ifi}),'HorizontalAlignment','left');
    end
end



%surv_opt_obj
%'callback',{@ check_fmt_box,-80,-15,varin.thr_bottom,'%.0f'}

panel1=uipanel(xml_scrip_h.options_panel,'units','normalized','Position',[0 2/3 1 1/3],'title','Channel, Integration Grid, bounds','BackgroundColor','white','fontweight','normal');
panel2=uipanel(xml_scrip_h.options_panel,'units','normalized','Position',[0 1/6 1 1/2],'title','Options','BackgroundColor','white','fontweight','normal');
panel3=uipanel(xml_scrip_h.options_panel,'units','normalized','Position',[0 0 1 1/6],'title','Exports','BackgroundColor','white','fontweight','normal');

gui_fmt=init_gui_fmt_struct('norm',5,2);
pos=create_pos_3(5,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

uicontrol(panel1,gui_fmt.txtTitleStyle,'String','Main Channel','Position',pos{1,1}{1});
xml_scrip_h.Options.Frequency=uicontrol(panel1,gui_fmt.popumenuStyle,'String',num2cell(survey_input_obj.Options.FrequenciesToLoad),...
    'Value',find(survey_input_obj.Options.Frequency==survey_input_obj.Options.FrequenciesToLoad),'Position',pos{1,1}{2}+[0 0 gui_fmt.box_w 0],'Tag','Frequency');

if ~isempty(p.Results.main_figure)
    curr_disp=init_grid_val(p.Results.main_figure);
else
    curr_disp=[];
end
if ~isempty(curr_disp)
    [dx,dy]=curr_disp.get_dx_dy();
else
    dx=5;
    dy=5;
end

uicontrol(panel1,gui_fmt.txtStyle,'String','Vertical slice size','Position',pos{2,1}{1});
xml_scrip_h.Options.Vertical_slice_size=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{2,1}{2},'string',dx,'Tag','Vertical_slice_size','callback',{@check_fmt_box,0,Inf,surv_opt_obj.Vertical_slice_size,'%.2f'});
uicontrol(panel1,gui_fmt.txtStyle,'String','Horizontal slice size','Position',pos{3,1}{1});
xml_scrip_h.Options.Horizontal_slice_size=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{3,1}{2},'string',dy,'Tag','Horizontal_slice_size','callback',{@check_fmt_box,0,Inf,surv_opt_obj.Horizontal_slice_size,'%.2'});

units_w= {'meters','pings','seconds'};
w_unit_idx=find(strcmp(survey_input_obj.Options.Vertical_slice_units,units_w));
xml_scrip_h.Options.Vertical_slice_units=uicontrol(panel1,gui_fmt.popumenuStyle,'String',units_w,'Value',w_unit_idx,'Position',pos{2,2}{1}-[0 0 gui_fmt.txt_w/2 0],'Tag','Vertical_slice_units');

uicontrol(panel1,gui_fmt.txtStyle,'String','Min Depth (m)','Position',pos{4,1}{1});
xml_scrip_h.Options.DepthMin=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{4,1}{2},'string',surv_opt_obj.DepthMin,'Tag','DepthMin','callback',{@check_fmt_box,0,Inf,surv_opt_obj.DepthMin,'%.1f'});

uicontrol(panel1,gui_fmt.txtStyle,'String','Max Depth(m)','Position',pos{4,2}{1});
xml_scrip_h.Options.DepthMax=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{4,2}{2},'string',surv_opt_obj.DepthMax,'Tag','DepthMax','callback',{@check_fmt_box,0,Inf,surv_opt_obj.DepthMax,'%.1f'});

uicontrol(panel1,gui_fmt.txtStyle,'String','Soundspeed(m/s)','Position',pos{5,1}{1});
xml_scrip_h.Options.Soundspeed=uicontrol(panel1,gui_fmt.edtStyle,'position',pos{5,1}{2},'string',surv_opt_obj.Soundspeed,'Tag','Soundspeed','callback',{@check_fmt_box,1400,1600,surv_opt_obj.Soundspeed,'%.2f'});


gui_fmt=init_gui_fmt_struct('norm',6,2);
pos=create_pos_3(6,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

xml_scrip_h.Options.SvThr_bool=uicontrol(panel2,gui_fmt.chckboxStyle,'String','Sv Thr(dB)','Position',pos{1,1}{1},'Value',0,'Tag','SvThr_bool');
xml_scrip_h.Options.SvThr=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{1,1}{2},'string',-999,'Tag','SvThr','callback',{@check_fmt_box,-999,0,surv_opt_obj.SvThr,'%.0f'});

uicontrol(panel2,gui_fmt.txtStyle,'String','Bad Transmits % thr.','Position',pos{1,2}{1});
xml_scrip_h.Options.BadTransThr=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{1,2}{2},'string','100','callback',{@ check_fmt_box,0,100,surv_opt_obj.BadTransThr,'%.0f'},'visible','on','tag','BadTransThr');

xml_scrip_h.Options.Es60_correction_bool=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',0,'String','ES60 correction (dB)','Position',pos{2,1}{1},'visible','on','tag','Es60_correction_bool');
xml_scrip_h.Options.Es60_correction=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{2,1}{2},'string',num2str(surv_opt_obj.Es60_correction),'callback',{@ check_fmt_box,0,inf,surv_opt_obj.Es60_correction,'%.2f'},'visible','on','tag','Es60_correction');

xml_scrip_h.Options.Shadow_zone=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_opt_obj.Shadow_zone,'String','Shadow zone Est. (m)','Position',pos{2,2}{1},'visible','on','tag','Shadow_zone');
xml_scrip_h.Options.Shadow_zone_height=uicontrol(panel2,gui_fmt.edtStyle,'position',pos{2,2}{2},'string',num2str(surv_opt_obj.Shadow_zone_height),'callback',{@ check_fmt_box,0,inf,surv_opt_obj.Shadow_zone_height,'%.1f'},'visible','on','tag','Shadow_zone_height');


xml_scrip_h.Options.Use_exclude_regions=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_opt_obj.Use_exclude_regions,'String','Rm. Bad Data Regions','Position',pos{3,1}{1},'tag','Use_exclude_regions');
xml_scrip_h.Options.Denoised=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_opt_obj.Denoised,'String','Denoised data','Position',pos{3,2}{1},'tag','Denoised');

xml_scrip_h.Options.Motion_correction=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_opt_obj.Motion_correction,'String','Motion Correction','Position',pos{4,1}{1},'tag','Motion_correction');
xml_scrip_h.Options.CopyBottomFromFrequency=uicontrol(panel2,gui_fmt.chckboxStyle,'position',pos{4,2}{1},'Value',surv_opt_obj.CopyBottomFromFrequency,'String','Copy Bot. from main Freq','tag','CopyBottomFromFrequency');

xml_scrip_h.Options.Remove_ST=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_opt_obj.Remove_ST,'String','Rm. Single Targets','Position',pos{5,1}{1},'tag','Remove_ST');
xml_scrip_h.Options.Remove_tracks=uicontrol(panel2,gui_fmt.chckboxStyle,'Value',surv_opt_obj.Remove_tracks,'String','Remove Tracks','Position',pos{5,2}{1},'tag','Remove_tracks');



gui_fmt=init_gui_fmt_struct('norm',2,2);
pos=create_pos_3(2,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

xml_scrip_h.Options.SaveBot=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{1,1}{1},'Value',surv_opt_obj.SaveBot,'String','Save Bottom','tag','SaveBot');
xml_scrip_h.Options.SaveReg=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{1,2}{1},'Value',surv_opt_obj.SaveReg,'String','Save Regions','tag','SaveReg');
xml_scrip_h.Options.ExportRegions=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{2,1}{1},'Value',surv_opt_obj.ExportRegions,'String','Export Regions','tag','ExportRegions');
xml_scrip_h.Options.ExportSlicedTransects=uicontrol(panel3,gui_fmt.chckboxStyle,'position',pos{2,2}{1},'Value',surv_opt_obj.ExportSlicedTransects,'String','Export Sliced transects','tag','ExportSlicedTransects');

fields_opt=fieldnames(xml_scrip_h.Options);
for iopt=1:numel(fields_opt)
    set(xml_scrip_h.Options.(fields_opt{iopt}),'callback',@update_survey_input_options);
end


colNames={'Denoise','Bot. Detect V1','Bot. Detect V2','Spikes Removal','Bad Pings','School Detect','Single Target','Track Target'};

col_fmt=cell(1,numel(colNames)+1);
col_fmt(:)={'logical'};
col_fmt(1)={'numeric'};

col_edit=true(1,numel(colNames)+1);
col_edit(1)=false;

data_init=cell(numel(surv_opt_obj.FrequenciesToLoad),numel(colNames));
data_init(:,1)=num2cell(surv_opt_obj.FrequenciesToLoad);
data_init(:,2)={0};

xml_scrip_h.algo_table=uitable('Parent',xml_scrip_h.algos_panel,...
    'Data', data_init,...
    'ColumnName', [{'Freq.'} colNames],...
    'ColumnFormat',col_fmt,...
    'ColumnEditable', col_edit,...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);
xml_scrip_h.algo_table.UserData.AlgosNames={'Denoise','BottomDetection','BottomDetectionV2','SpikesRemoval','BadPingsV2','SchoolDetection','SingleTarget','TrackTarget'};
set(xml_scrip_h.algo_table,'CellEditCallback',{@edit_algos_process_data_cback});
xml_scrip_h.process_list=process_cl.empty();


gui_fmt=init_gui_fmt_struct('norm',10,2);
pos=create_pos_3(10,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
% possible values and default
ref = {'Surface','Bottom','Transducer'};
ref_idx = 1;

% text
xml_scrip_h.reg_wc.bool=uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.chckboxStyle,...
    'String','Region WC:',...
    'FontWeight','Bold',...
    'Position',pos{1,1}{1});

uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Reference (Ref):',...
    'Position',pos{2,1}{1});

% value
xml_scrip_h.reg_wc.Ref = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',ref,...
    'Value',ref_idx,...
    'Position',pos{2,1}{2}+[0 0 gui_fmt.box_w 0]);


%% Region type

% possible values and default
data_type = {'Data' 'Bad Data'};
data_idx = 1;

% text
uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Data Type (Type):',...
    'Position',pos{3,1}{1});

% value
xml_scrip_h.reg_wc.Type = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',data_type,...
    'Value',data_idx,...
    'Position',pos{3,1}{2}+[0 0 gui_fmt.box_w 0]);

% ymin text
 uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.txtStyle,...
    'BackgroundColor','white',...
    'String','R min (m):',...
    'Position',pos{4,1}{1});

% ymin value
xml_scrip_h.reg_wc.y_min = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{4,1}{2},...
    'string',0,...
    'Tag','w');


% ymax text
 uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','R max (m):',...
    'Position',pos{4,2}{1});

% ymax value
xml_scrip_h.reg_wc.y_max = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{4,2}{2},...
    'string',inf,...
    'Tag','w');

%% Cell width

% possible values and default
units_w = {'pings','meters'};
w_unit_idx = 1;

% text
uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Cell Width:',...
    'Position',pos{5,1}{1});

% value
xml_scrip_h.reg_wc.Cell_w = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{5,1}{2},...
    'string',10,...
    'Tag','w');

% unit
xml_scrip_h.reg_wc.Cell_w_unit = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',units_w,...
    'Value',w_unit_idx,...
    'units','normalized',...
    'Position',pos{5,1}{2}+[gui_fmt.x_sep+gui_fmt.box_w 0 gui_fmt.box_w 0],...
    'Tag','w');

%% cell height

% possible values and default
units_h = {'meters','samples'};
h_unit_idx = 1;

% text
uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.txtStyle,...
    'String','Cell Height:',...
    'Position',pos{6,1}{1});

% value
xml_scrip_h.reg_wc.Cell_h = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.edtStyle,...
    'position',pos{6,1}{2},...
    'string',10,...
    'Tag','h');

% unit
xml_scrip_h.reg_wc.Cell_h_unit = uicontrol(xml_scrip_h.regions_panel,...
    gui_fmt.popumenuStyle,...
    'String',units_h,...
    'Value',h_unit_idx,...
    'Position',pos{6,1}{2}+[gui_fmt.x_sep+gui_fmt.box_w 0 gui_fmt.box_w 0],...
    'Tag','h');


fields_wc=fieldnames(xml_scrip_h.reg_wc);
for iwc=1:numel(fields_wc)
       set(xml_scrip_h.reg_wc.(fields_wc{iwc}),'callback',{@update_reg_wc_region,fields_wc{iwc}});
    if ~strcmp(fields_wc{iwc},'bool')
        if xml_scrip_h.reg_wc.bool.Value>0
            set(xml_scrip_h.reg_wc.(fields_wc{iwc}),'enable','on');
        else
            set(xml_scrip_h.reg_wc.(fields_wc{iwc}),'enable','off');
        end
    end
end



xml_scrip_h.reg_only=uicontrol(xml_scrip_h.regions_panel,gui_fmt.chckboxStyle,'Value',1,'String','Integrate by','Position',pos{8,1}{1},'Tooltipstring','unchecked: integrate all WC within bounds','Fontweight','bold');
int_opt={'Tag' 'IDs' 'Name' 'All Data Regions'};
xml_scrip_h.tog_int=uicontrol(xml_scrip_h.regions_panel,gui_fmt.popumenuStyle,'String',int_opt,'Value',1,'Position',pos{8,1}{2}+[0 0 gui_fmt.box_w 0]);
uicontrol(xml_scrip_h.regions_panel,gui_fmt.txtStyle,'position',pos{9,1}{1},'string','Specify: ');
xml_scrip_h.reg_id_box=uicontrol(xml_scrip_h.regions_panel,gui_fmt.edtStyle,'position',pos{9,1}{2}+[0 0 gui_fmt.box_w 0],'string','');


colNames={' ','Frequency (Hz)','G0 (dB)','SaCorr.(dB)','EQA(dB)','Alpha(db/km)'};
col_fmt=cell(1,numel(colNames));

col_fmt(:)={'numeric'};
col_fmt(1)={'logical'};

col_edit=true(1,numel(colNames));
col_edit(2)=false;

data_init=cell(numel(surv_opt_obj.FrequenciesToLoad),numel(colNames));

data_init(:,1)={1==1};
data_init(:,2)=num2cell(cal.FREQ);
data_init(:,3)=num2cell(cal.G0);
data_init(:,4)=num2cell(cal.SACORRECT);
data_init(:,5)=num2cell(cal.EQA);
data_init(:,6)=num2cell(cal.alpha);

xml_scrip_h.cal_f_table=uitable('Parent',xml_scrip_h.cal_f_panel,...
    'Data', data_init,...
    'ColumnName',  colNames,...
    'ColumnFormat',col_fmt,...c
    'ColumnEditable', col_edit,...
    'CellEditCallback',@cell_edit_cback,...
    'CellSelectionCallback',{},...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);


%%%%%%%%%%%%Transects table section%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt_table_panel=uipanel(xml_scrip_h.transect_panel,'units','normalized','Position',[0 0.8 1 0.2],'title','','BackgroundColor','white','fontweight','normal');
table_panel=uipanel(xml_scrip_h.transect_panel,'units','normalized','Position',[0 0 1 0.8],'title','','BackgroundColor','white','fontweight','normal');

colNames={' ','Folder','Snapshot','Type','Stratum','Transect','Comment'};
col_fmt={'logical' 'char' 'numeric' 'char' 'char' 'numeric' 'char' };

col_edit=false(1,numel(colNames));
col_edit(1)=true;

[data_init,log_files]=get_table_data_from_survey_input_obj(p.Results.survey_input_obj,p.Results.logbook_file);

xml_scrip_h.transects_table=uitable('Parent',table_panel,...
    'Data', data_init,...
    'ColumnName',  colNames,...
    'ColumnFormat',col_fmt,...
    'ColumnEditable', col_edit,...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);

gui_fmt=init_gui_fmt_struct('norm',2,2);
pos=create_pos_3(2,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

xml_scrip_h.logbook_table = uitable('Parent',opt_table_panel,...
    'Data',log_files(:),...
    'ColumnName',{'Logbooks in table'},...
    'ColumnFormat',{'char'},...
    'ColumnEditable',false,...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Units','normalized',...
    'Position',[0 0 gui_fmt.txt_w+gui_fmt.box_w 1]);
xml_scrip_h.logbook_table.UserData.select=[];
table_width=getpixelposition(xml_scrip_h.logbook_table);
set(xml_scrip_h.logbook_table,'ColumnWidth',{table_width(3)});

rc_menu = uicontextmenu(ancestor(xml_scrip_h.logbook_table,'figure'));
uimenu(rc_menu,'Label','Add Logbook','Callback',{@add_logbook_cback,xml_scrip_h.logbook_table,1});
uimenu(rc_menu,'Label','Remove entry(ies)','Callback',{@add_logbook_cback,xml_scrip_h.logbook_table,-1});
xml_scrip_h.logbook_table.UIContextMenu =rc_menu;

%%%%%Create Scripts section%%%%%%%%%%

if ~isempty(p.Results.main_figure)
    app_path=get_esp3_prop('app_path');
    p_scripts=app_path.scripts;
else
    p_scripts=pwd;
end
uicontrol(xml_scrip_h.validation_panel,gui_fmt.txtStyle,...
    'Position',[0.05 0.65 0.2 0.15],...
    'string','File:','Tooltipstring',sprintf('in folder: %s',p_scripts),...
    'HorizontalAlignment','Right');
str_fname=generate_valid_filename([survey_input_obj.Infos.Voyage '_' survey_input_obj.Infos.SurveyName]);
xml_scrip_h.f_name_edit = uicontrol(xml_scrip_h.validation_panel,gui_fmt.edtStyle,...
    'Position',[0.3 0.65 0.45 0.15],...
    'BackgroundColor','w',...
    'string', [str_fname '.xml'],...
    'HorizontalAlignment','left','Callback',@checkname_cback);

uicontrol(xml_scrip_h.validation_panel,gui_fmt.pushbtnStyle,...
    'Position',[0.3 0.3 0.3 0.2],...
    'string','Create ',...
    'Callback',{@create_script_cback,p.Results.main_figure});

setappdata(xml_scrip_fig,'xml_scrip_h',xml_scrip_h);
setappdata(xml_scrip_fig,'survey_input_obj',survey_input_obj);

set(xml_scrip_fig,'visible','on');
end

function cell_select_cback(src,evt)
src.UserData.select=evt.Indices;
end

function add_logbook_cback(src,evt,tb,id)
xml_scrip_fig=ancestor(src,'figure');
xml_scrip_h=getappdata(xml_scrip_fig,'xml_scrip_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');

if id<0 || ~isempty(tb.UserData.select)
    tb.Data(tb.UserData.select)=[];
     [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,tb.Data);
     tb.Data=log_files(:);
     xml_scrip_h.transects_table.Data=data_init;
else
    path_init= tb.Data(tb.UserData.select);
    if isempty(path_init)
        path_init=tb.Data;
    end
    if isempty(path_init)
        path_init={pwd};
    end
    
    path_init=path_init{1};
        [~,path_f]= uigetfile({fullfile(path_init,'echo_logbook.db')}, 'Pick a logbook file','MultiSelect','off');
        if path_f==0
            return;
        end
        [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,union({path_f},tb.Data));
         tb.Data=log_files(:);
        xml_scrip_h.transects_table.Data=data_init;
end
end

function create_script_cback(src,evt,main_figure)

xml_scrip_fig=ancestor(src,'figure');
xml_scrip_h=getappdata(xml_scrip_fig,'xml_scrip_h');

survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');

    app_path=get_esp3_prop('app_path');
    p_scripts=app_path.scripts;

algos_lists=xml_scrip_h.process_list();
ialin=0;
al_out={};
f_tot=[];
for ial=1:numel(algos_lists)
    f=algos_lists(ial).Freq;
    algos=algos_lists(ial).Algo;
    f_tot=union(f,f_tot);
    for iali=1:numel(algos)
        ialin=ialin+1;
        al_out{ialin}.Name=algos(iali).Name;
        al_out{ialin}.Varargin=algos(iali).input_params_to_struct;
        al_out{ialin}.Varargin.Frequencies=f;
    end
end

survey_input_obj.Algos=al_out;
int_opt=xml_scrip_h.tog_int.String;
switch int_opt{xml_scrip_h.tog_int.Value}
    case 'All Data Regions'
        ids='IDs';
        ids_str='';
    otherwise
        ids=int_opt{xml_scrip_h.tog_int.Value};
        ids_str=xml_scrip_h.reg_id_box.String;
end
data_init=xml_scrip_h.transects_table.Data;
if isempty(data_init)
    warndlg_perso(main_figure,'No data','Nothing to put in the script.');
    return;
end
surv_data_struct.Folder=data_init(:,2);
surv_data_struct.Snapshot=cell2mat(data_init(:,3));
surv_data_struct.Type=data_init(:,4);
surv_data_struct.Stratum=data_init(:,5);
surv_data_struct.Transect=cell2mat(data_init(:,6));
idx_struct=cell2mat(data_init(:,1));
survey_input_obj.complete_survey_input_cl_from_struct(surv_data_struct,idx_struct,ids,ids_str);

data_init=xml_scrip_h.cal_f_table.Data;

idx_struct=find(cell2mat(data_init(:,1)));
cal.FREQ=cell2mat(data_init(:,2));
idx_f=union(idx_struct,find(ismember(cal.FREQ,f_tot)));

cal.FREQ=cal.FREQ(idx_f);
cal.G0=cell2mat(data_init(idx_f,3));
cal.CID=cell(size(idx_f));
cal.SACORRECT=cell2mat(data_init(idx_f,4));
cal.EQA=cell2mat(data_init(idx_f,5));
cal.alpha=cell2mat(data_init(idx_f,6));
survey_input_obj.Cal=[];

for i=1:length(cal.FREQ)
    cal_temp.FREQ=cal.FREQ(i);
    cal_temp.G0=cal.G0(i);
    cal_temp.SACORRECT=cal.SACORRECT(i);
     cal_temp.EQA=cal.EQA(i);
     survey_input_obj.Cal=[survey_input_obj.Cal cal_temp];
end
survey_input_obj.Options.FrequenciesToLoad=cal.FREQ;
survey_input_obj.Options.Absorption=cal.alpha;

survey_input_obj.survey_input_to_survey_xml('xml_filename',fullfile(p_scripts,xml_scrip_h.f_name_edit.String));
open_txt_file(fullfile(p_scripts,xml_scrip_h.f_name_edit.String));
end

function update_reg_wc_region(src,evt,field)

xml_scrip_fig=ancestor(src,'figure');
xml_scrip_h=getappdata(xml_scrip_fig,'xml_scrip_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');
reg_def=struct(...
        'y_min',0,...
        'y_max',Inf,...
        'Ref','surface',...
        'Type','data',...
        'Cell_w',10,...
        'Cell_h',10,...
        'Cell_w_unit','pings',...
        'Cell_h_unit','meters'...
        );
switch src.Style
    case 'edit'
        val=str2double(src.String);
        if isnan(val)
            src.String=num2str(reg_def.(field));
        end  
end


fields_wc=fieldnames(xml_scrip_h.reg_wc);
for iwc=1:numel(fields_wc)
    if ~strcmp(fields_wc{iwc},'bool')
        if xml_scrip_h.reg_wc.bool.Value>0
            set(xml_scrip_h.reg_wc.(fields_wc{iwc}),'enable','on');
        else
            set(xml_scrip_h.reg_wc.(fields_wc{iwc}),'enable','off');
        end
    end
end
        
if xml_scrip_h.reg_wc.bool.Value
    ref = get(xml_scrip_h.reg_wc.Ref,'String');
    ref_idx = get(xml_scrip_h.reg_wc.Ref,'value');
    
    data_type = get(xml_scrip_h.reg_wc.Type,'String');
    data_type_idx = get(xml_scrip_h.reg_wc.Type,'value');
    
    h_units = get(xml_scrip_h.reg_wc.Cell_h_unit,'String');
    h_units_idx = get(xml_scrip_h.reg_wc.Cell_h_unit,'value');
    
    w_units = get(xml_scrip_h.reg_wc.Cell_w_unit,'String');
    w_units_idx = get(xml_scrip_h.reg_wc.Cell_w_unit,'value');
    
    y_min = str2double(get(xml_scrip_h.reg_wc.y_min,'string'));
    y_max = str2double(get(xml_scrip_h.reg_wc.y_max,'string'));
    
    cell_w = str2double(get(xml_scrip_h.reg_wc.Cell_w,'string'));
    cell_h = str2double(get(xml_scrip_h.reg_wc.Cell_h,'string'));
    
    
    Regions_WC{1}=struct(...
        'y_min',y_min,...
        'y_max',y_max,...
        'Ref',ref{ref_idx},...
        'Type',data_type{data_type_idx},...
        'Cell_w',cell_w,...
        'Cell_h',cell_h,...
        'Cell_w_unit',w_units{w_units_idx},...
        'Cell_h_unit',h_units{h_units_idx}...
        );

else
    Regions_WC={};
end
survey_input_obj.Regions_WC=Regions_WC;
end


function update_survey_input_options(src,evt)
xml_scrip_fig=ancestor(src,'figure');
xml_scrip_h=getappdata(xml_scrip_fig,'xml_scrip_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');
survey_opt_def=survey_options_cl();
opts_h=xml_scrip_h.Options;
switch src.Style
    case 'checkbox'
        if contains(src.Tag,'_bool')
            field=strrep(src.Tag,'_bool','');
            updt=get(src,'value');
            val=get(opts_h.(field),'string');
        else
            field=src.Tag;
            val=get(opts_h.(field),'value');
            updt=1;
        end
    case 'edit'
        field=src.Tag;
        if isfield(opts_h,[src.Tag '_bool'])
            updt=get(opts_h.([src.Tag '_bool']),'value');
        else
            updt=1;
        end
        val=get(opts_h.(field),'string');
    case 'popupmenu'
        field=src.Tag;
        switch field
            case 'ClassificationFile'
                val_cell=xml_scrip_h.classification_files;
            otherwise
                val_cell=get(opts_h.(field),'string');
        end
        
        if iscell(val_cell)
            val=val_cell{get(opts_h.(field),'value')};
        else
            val=val_cell(get(opts_h.(field),'value'));
        end
        updt=1;
end


if updt>0
    if ischar(survey_input_obj.Options.(field))
        survey_input_obj.Options.(field)=val;
    else
        if ischar(val)
            val=str2double(val);
        end
        if isnan(val)
            val=survey_opt_def.(field);
            set(opts_h.(field),'string',survey_opt_def.(field));
        end
        survey_input_obj.Options.(field)=val;
    end
    
else
    survey_input_obj.Options.(field)=survey_opt_def.(field);
    if ischar(survey_input_obj.Options.(field))
        set(opts_h.(field),'string',survey_opt_def.(field))
    else
        
        set(opts_h.(field),'string',num2str(survey_opt_def.(field)))
    end
end
%survey_input_obj.Options

end


function update_survey_input_infos(src,evt,field)
xml_scrip_fig=ancestor(src,'figure');
xml_scrip_h=getappdata(xml_scrip_fig,'xml_scrip_h');
survey_input_obj=getappdata(xml_scrip_fig,'survey_input_obj');
infos_h=xml_scrip_h.Infos;

val=get(infos_h.(field),'string');

survey_input_obj.Infos.(field)=val;

end



function checkname_cback(src,evt)

[~, file_n,~]=fileparts(src.String);
file_n=generate_valid_filename(file_n);
set(src,'String',[file_n '.xml']);

end

function edit_algos_process_data_cback(src,evt)

if isempty(evt.Indices)
    return;
end

xml_scrip_fig=ancestor(src,'Figure');
xml_scrip_h=getappdata(xml_scrip_fig,'xml_scrip_h');
algo=init_algos(src.UserData.AlgosNames(evt.Indices(2)-1));

freq=src.Data{evt.Indices(1),1};

add=evt.EditData;
src.Data{evt.Indices(1),evt.Indices(2)}=evt.EditData;
xml_scrip_h.process_list=xml_scrip_h.process_list.set_process_list(freq,algo,add);

setappdata(xml_scrip_fig,'xml_scrip_h',xml_scrip_h);

end

function cell_edit_cback(src,evt)
idx=evt.Indices;
row_id=idx(1);
if ~iscell(src.ColumnFormat{idx(2)})
    switch src.ColumnFormat{idx(2)}
        case 'char'
            src.Data{row_id,idx(2)}=strtrim(src.Data{row_id,idx(2)});
        case 'numeric'
            if isnan(evt.NewData)
                src.Data{row_id,idx(2)}=evt.PreviousData;
            end
    end
end
end
