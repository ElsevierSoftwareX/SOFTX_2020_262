%% keyboard_func.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |src|: TODO: write description and info on variable
% * |callbackdata|: TODO: write description and info on variable
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function keyboard_func(src,callbackdata,main_figure)


cursor_mode_tool_comp=getappdata(main_figure,'Cursor_mode_tool');
    
if ~isdeployed()
    disp_perso(main_figure,callbackdata.Key) ;
end


curr_disp=get_esp3_prop('curr_disp');

switch callbackdata.Key
    case {'f' 'e' 'f5' 'a' 'leftarrow','rightarrow','uparrow','downarrow','d','w','s'}
        layer=get_current_layer();
        if ~isempty(layer)
            [trans_obj,idx_freq]=layer.get_trans(curr_disp);
            if isempty(trans_obj)
                return;
            end
            number_lay=trans_obj.get_transceiver_pings();
            samples=trans_obj.get_transceiver_samples();
            
            xdata=number_lay;
            ydata=samples;
        else
            return;
        end
end



try
    switch callbackdata.Key
        
        case {'leftarrow','rightarrow','uparrow','downarrow','a','d','w','s'}
            
            
            axes_panel_comp=getappdata(main_figure,'Axes_panel');
            main_axes=axes_panel_comp.echo_obj.main_ax;
            

            x_lim=double(get(main_axes,'xlim'));
            y_lim=double(get(main_axes,'ylim'));
            dx=ceil((x_lim(2)-x_lim(1)));
            dy=(y_lim(2)-y_lim(1));
                       
            h_m=ceil(curr_disp.Move_dy_dx(2)*dx);
            v_m=curr_disp.Move_dy_dx(1)*dy;
            
            switch callbackdata.Key
                
                case {'a' 'leftarrow'}
                    if strcmpi(callbackdata.Modifier,'control')
                        if ~isempty(trans_obj.Regions) && strcmpi(callbackdata.Key,'a')
                            curr_disp.setActive_reg_ID({trans_obj.Regions(:).Unique_ID});
                        end
                    else
                        if x_lim(1)>xdata(1)
                            x0=nanmax(xdata(1),x_lim(1)-h_m);
                            x_lim=[x0,x0+dx];
                            
                            set(main_axes,'xlim',x_lim);
                            set(main_axes,'ylim',y_lim);
                        end
                    end
                    
                case {'rightarrow' 'd'}
                    if x_lim(2)<xdata(end)
                        
                        x1=nanmin(xdata(end),x_lim(2)+h_m);
                        x_lim=[x1-dx,x1];
                        
                        set(main_axes,'xlim',x_lim);
                        set(main_axes,'ylim',y_lim);
                    end
                case {'downarrow'}
                    if y_lim(2)<ydata(end)
                        y_lim=[nanmin(ydata(end),y_lim(2)+v_m)-dy,nanmin(ydata(end),y_lim(2)+v_m)];
                        set(main_axes,'ylim',y_lim);
                    end
                case 's'
                    
                    if isempty(callbackdata.Modifier)
                        if y_lim(2)<ydata(end)
                            y_lim=[nanmin(ydata(end),y_lim(2)+v_m)-dy,nanmin(ydata(end),y_lim(2)+v_m)];
                            set(main_axes,'ylim',y_lim);
                        end
                    elseif all(ismember({'control' 'shift'},callbackdata.Modifier))
                        save_bot_reg_xml_to_db_callback([],[],main_figure,1,1);
                    elseif strcmpi(callbackdata.Modifier,'control')
                        save_bot_reg_xml_to_db_callback([],[],main_figure,0,0);
                    end
                    
                case {'uparrow' 'w'}
                    if y_lim(1)>ydata(1)
                        y_lim=[nanmax(ydata(1),y_lim(1)-v_m),nanmax(ydata(1),y_lim(1)-v_m)+dy];
                        set(main_axes,'ylim',y_lim);
                    end
            end
        case {'0' 'numpad0'}
            curr_disp.CursorMode='Normal';
        case {'1' 'numpad1'}
            
            if isempty(callbackdata.Modifier)
                zi='zin';
            elseif strcmpi(callbackdata.Modifier,'shift')
                zi='zout';
            else
                return;
            end
            
            switch zi
                case 'zin'
                    
                    switch get(cursor_mode_tool_comp.zoom_in,'state')
                        case 'off'
                            set(cursor_mode_tool_comp.zoom_in,'state','on');
                            curr_disp.CursorMode='Zoom In';
                        case 'on'
                            set(cursor_mode_tool_comp.zoom_in,'state','off');
                            curr_disp.CursorMode='Normal';
                    end
                case 'zout'
                    switch get(cursor_mode_tool_comp.zoom_out,'state')
                        case 'off'
                            set(cursor_mode_tool_comp.zoom_out,'state','on');
                            curr_disp.CursorMode='Zoom Out';
                        case 'on'
                            set(cursor_mode_tool_comp.zoom_out,'state','off');
                            curr_disp.CursorMode='Normal';
                            
                    end
            end
        case {'2' 'numpad2'}
            
            switch get(cursor_mode_tool_comp.bad_trans,'state')
                case 'off'
                    set(cursor_mode_tool_comp.bad_trans,'state','on');
                    curr_disp.CursorMode='Bad Pings';
                case 'on'
                    set(cursor_mode_tool_comp.bad_trans,'state','off');
                    curr_disp.CursorMode='Normal';
            end
        case {'3' 'numpad3'}
            
            switch get(cursor_mode_tool_comp.edit_bottom,'state')
                case 'off'
                    set(cursor_mode_tool_comp.edit_bottom,'state','on');
                    curr_disp.CursorMode='Edit Bottom';
                case 'on'
                    set(cursor_mode_tool_comp.edit_bottom,'state','off');
                    curr_disp.CursorMode='Normal';
            end
        case {'4' 'numpad4'}
            switch get(cursor_mode_tool_comp.create_reg,'state')
                case 'off'
                    set(cursor_mode_tool_comp.create_reg,'state','on');
                    curr_disp.CursorMode='Create Region';
                case 'on'
                    set(cursor_mode_tool_comp.create_reg,'state','off');
                    curr_disp.CursorMode='Normal';
            end
        case {'6' 'numpad6'}
            switch curr_disp.CursorMode
                case 'Pan'
                    curr_disp.CursorMode='Normal';
                otherwise
                    curr_disp.CursorMode='Pan';
            end
        case {'7' 'numpad7'}
            switch curr_disp.CursorMode
                case 'Draw Line'
                    curr_disp.CursorMode='Normal';
                otherwise
                    curr_disp.CursorMode='Draw Line';
            end
        case {'8' 'numpad8'}
            switch curr_disp.CursorMode
                case 'Add ST'
                    curr_disp.CursorMode='Normal';
                otherwise
                    curr_disp.CursorMode='Add ST';
            end
        case {'5' 'numpad5'}
            switch get(cursor_mode_tool_comp.measure,'state')
                case 'off'
                    set(cursor_mode_tool_comp.measure,'state','on');
                    curr_disp.CursorMode='Measure';
                case 'on'
                    set(cursor_mode_tool_comp.measure,'state','off');
                    curr_disp.CursorMode='Normal';
            end
        case {'b','pagedown'}
            
            switch curr_disp.DispUnderBottom
                case 'off'
                    curr_disp.DispUnderBottom='on';
                case 'on'
                    curr_disp.DispUnderBottom='off';
            end
            
        case 'r'
            if isempty(callbackdata.Modifier)
                
                switch curr_disp.DispReg
                    case 'off'
                        curr_disp.DispReg='on';
                    case 'on'
                        curr_disp.DispReg='off';
                end
            elseif strcmpi(callbackdata.Modifier,'control')
                
                import_bot_regs_from_xml_callback ([],[],main_figure,-1,-1);
            end
            
        case 't'
            if isempty(callbackdata.Modifier)
                switch curr_disp.DispBadTrans
                    case 'off'
                        curr_disp.DispBadTrans='on';
                    case 'on'
                        curr_disp.DispBadTrans='off';
                end
            elseif  strcmpi(callbackdata.Modifier,'shift')
                switch curr_disp.DispSpikes
                    case 'off'
                        curr_disp.DispSpikes='on';
                    case 'on'
                        curr_disp.DispSpikes='off';
                end
            end
        case 'c'
            if isempty(callbackdata.Modifier)
                cmaps=list_cmaps();
                id_map=find(strcmpi(curr_disp.Cmap,cmaps));
                if isempty(id_map)
                    id_map=0;
                end
                c_new=cmaps{nanmin(rem(id_map,length(cmaps))+1,length(cmaps))};
                
                curr_disp.Cmap=c_new;
            end
        case 'f'
            if length(layer.Frequencies)>1
                if isempty(callbackdata.Modifier)
                    curr_disp.ChannelID=layer.ChannelID{nanmin(rem(idx_freq,length(layer.ChannelID))+1,length(layer.ChannelID))};
                elseif  strcmpi(callbackdata.Modifier,'shift')
                    id=idx_freq-1;
                    id(id==0)=length(layer.ChannelID);
                    curr_disp.ChannelID=layer.ChannelID{id};
                end
            end
        case 'e'
            if~isempty(trans_obj.Data)
                if length(trans_obj.Data.Fieldname)>1
                    fields=trans_obj.Data.Fieldname;
                    id_field=find(strcmp(curr_disp.Fieldname,fields));
                    if isempty(callbackdata.Modifier)
                        curr_disp.setField(fields{nanmin(rem(id_field,length(fields))+1,length(fields))});
                    elseif  strcmpi(callbackdata.Modifier,'shift')
                        id=id_field-1;
                        id(id==0)=length(fields);
                        curr_disp.setField(fields{id});
                    end
                end
            end
            
        case 'n'
            if strcmpi(curr_disp.CursorMode,'normal')
                change_layer_callback([],[],main_figure,'next');
            end
        case 'p'
            if strcmpi(curr_disp.CursorMode,'normal')
                change_layer_callback([],[],main_figure,'prev');
            end
        case 'add'
            curr_disp=get_esp3_prop('curr_disp');
            curr_disp.setCax(curr_disp.Cax+1);
        case 'subtract'
            curr_disp=get_esp3_prop('curr_disp');
            curr_disp.setCax(curr_disp.Cax-1);
        case 'delete'
            delete_region_callback([],[],main_figure,curr_disp.Active_reg_ID);
        case 'l'
            show_status_bar(main_figure);
            load_bar_comp=getappdata(main_figure,'Loading_bar');
            load_bar_comp.progress_bar.setText('Loading Logbook');
            if isempty(callbackdata.Modifier)
                load_logbook_tab_from_db(main_figure,0);
            elseif  strcmpi(callbackdata.Modifier,'shift')
                load_logbook_tab_from_db(main_figure,0,1);
            end
            hide_status_bar(main_figure);
        case 'y'
            if  strcmpi(callbackdata.Modifier,'control')
                uiundo(main_figure,'execRedo')
            end
        case 'z'
            if isempty(callbackdata.Modifier)
                go_to_ping(1,main_figure);
            elseif  strcmpi(callbackdata.Modifier,'control')
                uiundo(main_figure,'execUndo')
            end
        case 'home'
            go_to_ping(1,main_figure);
        case {'x' 'end'}
            go_to_ping(length(number_lay),main_figure);
        case {'escape'}
            curr_disp.CursorMode=curr_disp.CursorMode;
        case 'f5'
            echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
            curr_tab=echo_tab_panel.SelectedTab;
            
            if isfield(curr_tab.UserData,'db_file')
                db_file=curr_tab.UserData.db_file;
            else
                [path_lay,~]=get_path_files(layer);
                path_f=path_lay{1};
                
                db_file=fullfile(path_f,'echo_logbook.db');
            end
            disp_perso(main_figure,sprintf('Looking for new files for logbook %s',db_file));
            [file_added,files_rem]=layer_cl().update_echo_logbook_dbfile('main_figure',main_figure,'DbFile',db_file);
            
            if ~isempty(file_added)||~isempty(files_rem)
                dest_fig=getappdata(main_figure,'echo_tab_panel');
                [path_f,~]=fileparts(db_file);
                tag=sprintf('logbook_%s',path_f);
                tab_obj=findobj(dest_fig,'Tag',tag);
                
                if ~isempty(tab_obj)
                    reload_logbook_fig(tab_obj(1),file_added);
                end
            end
        otherwise
            if ~isdeployed
                disp('Key not attributed key in Keyboard_func');
            end
    end
    %update_info_panel([],[],1);
catch err
    warning('Error in Keyboard_func while pressing %s',callbackdata.Key);
    print_errors_and_warnings(1,'error',err);
    hide_status_bar(main_figure); 
end


%
% profile off;
%
% profile viewer;
end