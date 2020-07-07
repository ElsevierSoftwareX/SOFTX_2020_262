function load_file_panel(main_figure,echo_tab_panel)

if isappdata(main_figure,'file_tab')
    file_tab_comp=getappdata(main_figure,'file_tab');
    delete(file_tab_comp.file_tab);
    rmappdata(main_figure,'file_tab',file_tab_comp);
end

app_path=get_esp3_prop('app_path');

file_tab_comp.file_tab=new_echo_tab(main_figure,echo_tab_panel,'Title','Files');

pos=getpixelposition(file_tab_comp.file_tab);

%javaComponentName = 'javax.swing.JFileChooser';
javaComponentName = 'com.mathworks.hg.util.dFileChooser';
%javaComponentName='com.mathworks.mwswing.MJFileChooserPerPlatform';


file_tab_comp.FileChooser = handle(javaObjectEDT(javaComponentName),'CallbackProperties');

% bgcolor = num2cell(get(main_figure, 'Color'));
% file_tab_comp.FileChooser.setBackground(java.awt.Color(bgcolor{:}));
% file_tab_comp.FileChooser.setForeground(java.awt.Color(bgcolor{:}));


file_tab_comp.FileChooser.setApproveButtonText(java.lang.String('Open'));
file_tab_comp.FileChooser.setPreferredSize(java.awt.Dimension(pos(3)/2,pos(4)*0.95));
file_tab_comp.FileChooser.setCurrentDirectory(java.io.File(app_path.data.Path_to_folder));
file_tab_comp.FileChooser.setMultiSelectionEnabled(true);
file_tab_comp.FileChooser.setDragEnabled(true);

globalPanel = javax.swing.JPanel(java.awt.BorderLayout);
%globalPanel.setBackground(java.awt.Color(bgcolor{:}));
[file_tab_comp.JPanel, file_tab_comp.JPanelContainer] = javacomponent(globalPanel, [0 0 pos(3)/2 pos(4)], file_tab_comp.file_tab);
set(file_tab_comp.JPanelContainer,'units','normalized');
file_tab_comp.JPanel.add(file_tab_comp.FileChooser);
file_tab_comp.FileChooser.repaint();
drawnow;

filterSpec={'Pick a raw/crest/asl/fcv30/logbook file (*.raw,d*,*A,*.lst,*.ini,*.db)' {'*.raw';'d*';'*A';'*.lst';'*.ini';'echo_logbook.db'}};

file_tab_comp.FileChooser.setAcceptAllFileFilterUsed(true);
fileFilter = {};

for filterIdx = 1 : size(filterSpec,1)
    fileFilter{end+1} = add_file_filter(file_tab_comp.FileChooser, filterSpec{filterIdx,:}); %#ok<AGROW>
end
try
    file_tab_comp.FileChooser.setFileFilter(fileFilter{1});  % use the first filter by default
catch
    % never mind - ignore...
end

file_tab_comp.FileChooser.PropertyChangeCallback  = {@file_select_cback,main_figure};
file_tab_comp.FileChooser.ActionPerformedCallback = {@button_cbacks,main_figure};


curr_disp=get_esp3_prop('curr_disp');

if isempty(curr_disp)
    base_curr='landcover';   
else
    base_curr=curr_disp.Basemap;
end

file_tab_comp.map_axes=geoaxes('Parent',file_tab_comp.file_tab,...
    'Units','normalized',...
    'OuterPosition',[0.5 0 0.5 1],...
    'basemap',base_curr);

format_geoaxes(file_tab_comp.map_axes);

%axtoolbar(file_tab_comp.map_axes,{'restoreview'},'Visible','on');

init_map_from_folder(file_tab_comp.map_axes,app_path.data.Path_to_folder);

file_tab_comp.tracks_plots=plot(file_tab_comp.map_axes,[],[]);

%set(file_tab_comp.file_tab,'SizeChangedFcn',{@resize_file_selector_cback,main_figure});

setappdata(main_figure,'file_tab',file_tab_comp);

end

function init_map_from_folder(ax,folder)

cla(ax);
%legend(ax,'off');

survey_data=get_survey_data_from_db(folder);
if isempty(survey_data{1})
    title(ax,'','Interpreter','none');
else
    title(ax,sprintf('Survey %s, Voyage %s',survey_data{1}{1}.SurveyName,survey_data{1}{1}.Voyage),'Interpreter','none');
end



end

% function resize_file_selector_cback(htab,~,main_figure)
% file_tab_comp=getappdata(main_figure,'file_tab');
% pos=getpixelposition(htab);
% file_tab_comp.JPanel.setPreferredSize(java.awt.Dimension(pos(3)/2,pos(4)*0.95));
% % jColor = java.awt.Color.red;  % or: java.awt.Color(1,0,0)
% % jNewBorder = javax.swing.border.LineBorder(jColor, 1, true);  % red, 1px, rounded=true
% % file_tab_comp.JPanel.setBorder(jNewBorder);
% file_tab_comp.JPanel.repaint();
% end

function file_select_cback(FileChooser, eventData, main_figure)
try
    
    
    switch char(eventData.getPropertyName)
        case 'SelectedFilesChangedProperty'
            file_tab_comp=getappdata(main_figure,'file_tab');
            
            if~isdeployed()
                disp('Map Update');
            end

            tmp = FileChooser.getSelectedFiles;
            files=cell(1,numel(tmp));
            
            for i=1:numel(tmp)
                files{i}=char(tmp(i));
            end
            if isempty(files)
                %legend(file_tab_comp.map_axes,'off');
                return;
            end
            
            if ~isempty(file_tab_comp.tracks_plots)
                file_tab_comp.tracks_plots(~isvalid(file_tab_comp.tracks_plots))=[];
            end
            
            if ~isempty(file_tab_comp.tracks_plots)
                idx_rem=~ismember({file_tab_comp.tracks_plots(:).Tag},files);
                delete(file_tab_comp.tracks_plots(idx_rem));
                file_tab_comp.tracks_plots(idx_rem)=[];
                [~,idx_new]=setdiff(files,{file_tab_comp.tracks_plots(:).Tag});
                files=files(idx_new);
            end
            
            file_old=cell(1,numel(file_tab_comp.tracks_plots));
            gps_data_old=cell(1,numel(file_tab_comp.tracks_plots));
            txt_old=cell(1,numel(file_tab_comp.tracks_plots));
            
            for iold=1:numel(file_tab_comp.tracks_plots)
                gps_data_old{iold}=file_tab_comp.tracks_plots(iold).UserData.gps;
                file_old{iold}=file_tab_comp.tracks_plots(iold).UserData.file;
                txt_old{iold}=file_tab_comp.tracks_plots(iold).UserData.txt;
            end
            
            [~,idx_keep]=unique(file_old);
            
            txt_old=txt_old(idx_keep);
            file_old=file_old(idx_keep);
            gps_data_old=gps_data_old(idx_keep);
            
            
            delete(file_tab_comp.tracks_plots);
            file_tab_comp.tracks_plots=[];
            
            cla(file_tab_comp.map_axes);
            
            survey_data=get_survey_data_from_db(files);
            idx_rem=cellfun(@numel,survey_data)==0;
            files(idx_rem)=[];
            survey_data(idx_rem)=[];
            if ~isempty(files)
                gps_data=get_ping_data_from_db(files,[]);
            else
                gps_data={};
            end
            txt=cell(1,numel(files));
            
            for ifi=1:numel(files)
                if ~isempty(gps_data{ifi})
                    [~,text_str,ext_str]=fileparts(files{ifi});
                    text_str=[text_str ext_str ' '];
                    for is=1:length(survey_data{ifi})
                        text_str=[text_str survey_data{ifi}{is}.print_survey_data ' '];
                    end
                    txt{ifi}=text_str;
                else
                    
                    
                end
            end
            
            gps_data=[gps_data gps_data_old];
            txt=[txt txt_old];
            files=[files file_old];
            idx_empty=cellfun(@isempty,gps_data);
            if all(idx_empty)
                %legend(file_tab_comp.map_axes,'off');
                return;
            end
            files(idx_empty)=[];
            gps_data(idx_empty)=[];
            txt(idx_empty)=[];
            
            LatLim_cell=cellfun(@(x) [nanmin(x.Lat) nanmax(x.Lat)],gps_data,'un',0);
            LonLim_cell=cellfun(@(x) [nanmin(x.Long) nanmax(x.Long)],gps_data,'un',0);
            
            idx_rem=cellfun(@(x) all(x==[-90 90]),LatLim_cell)|cellfun(@(x) all(x==[-180 180]),LonLim_cell);
            LatLim_cell(idx_rem)=[];
            LonLim_cell(idx_rem)=[];
        
            if~isempty(LatLim_cell)
                latLim2=max(cellfun(@max,LatLim_cell));
                latLim1=min(cellfun(@min,LatLim_cell));
                
                longLim2=max(cellfun(@max,LonLim_cell));
                longLim1=min(cellfun(@min,LonLim_cell));
                
                [LatLim,LongLim] = ext_lat_lon_lim_v2([latLim1 latLim2],[longLim1 longLim2],0.2);
            else
               return;
            end

 
            for ifi=1:numel(files)
                if ~isempty(gps_data{ifi})
                    userdata.txt=txt{ifi};
                    userdata.gps=gps_data{ifi};
                    userdata.file=files{ifi};
                    new_plots=[geoplot(file_tab_comp.map_axes,gps_data{ifi}.Lat(1),gps_data{ifi}.Long(1),'Marker','o','Tag',files{ifi},'Color',[0 0.6 0],'UserData',userdata,'Markersize',4,'LineWidth',1,'MarkerFaceColor',[0 0.6 0]) ...
                        geoplot(file_tab_comp.map_axes,gps_data{ifi}.Lat,gps_data{ifi}.Long,'Tag',files{ifi},'UserData',userdata,'ButtonDownFcn',@disp_obj_tag_callback,'linewidth',1,'Color',[0 0 0])] ;
                    file_tab_comp.tracks_plots=[file_tab_comp.tracks_plots new_plots];
                    
                    
                    % set hand pointer when on that line
                    pointerBehavior.enterFcn    = [];
                    pointerBehavior.exitFcn     = @(src, evt) exit_map_plot_fcn(src, evt,new_plots(2));
                    pointerBehavior.traverseFcn = @(src, evt) traverse_map_plot_fcn(src, evt,new_plots(2));
                    iptSetPointerBehavior(new_plots(2),pointerBehavior);
                    
                else
                    
                end
            end
            
            try
                [LatLim,LongLim] = ext_lat_lon_lim_v2(LatLim,LongLim,0.2);
                geolimits(file_tab_comp.map_axes,LatLim,LongLim);
                set(file_tab_comp.map_axes,'visible','on')
            catch
                warning('area too small for ticks to display')
            end
            
            
            %profile off;
            %profile viewer;
            setappdata(main_figure,'file_tab',file_tab_comp);
        case 'directoryChanged'
            file_tab_comp=getappdata(main_figure,'file_tab');
            
            init_map_from_folder(file_tab_comp.map_axes,char(eventData.getNewValue));
            setappdata(main_figure,'file_tab',file_tab_comp);
        otherwise
            if~isdeployed()
                disp(eventData.getPropertyName);
            end
    end
    
catch err
    if ~isdeployed()
        disp('Error in file tab')
        rethrow(err);
    end
    % Never mind - bail out...
end

end



function fileFilter = add_file_filter(FileChooser, description, extension)
try
    if ~iscell(extension)
        extension = {extension};
    end
    
    if strcmp(extension{1},'*.*')
        jBasicFileChooserUI = javax.swing.plaf.basic.BasicFileChooserUI(FileChooser.java);
        fileFilter = javaObjectEDT('javax.swing.plaf.basic.BasicFileChooserUI$AcceptAllFileFilter',jBasicFileChooserUI);
    else
        extension = regexprep(extension,'^.*\*?\.','');
        fileFilter = com.mathworks.mwswing.FileExtensionFilter(description, extension, false, true);
    end
    javaMethodEDT('addChoosableFileFilter',FileChooser,fileFilter);
catch
    fileFilter = [];
end
end

function button_cbacks(FileChooser, eventData, main_figure)
switch char(eventData.getActionCommand)
    case 'CancelSelection'
        
    case 'ApproveSelection'
        files = cellfun(@char, cell(FileChooser.getSelectedFiles), 'uniform',0);
        
        if isempty(files)
            files = char(FileChooser.getSelectedFile);
        end
        esp3_obj=getappdata(groot,'esp3_obj');
        esp3_obj.open_file(files);
        
    otherwise
        % should never happen
end
end  % button_cbacks