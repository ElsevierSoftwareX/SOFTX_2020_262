function online=new_version_figure(main_figure)
echo_ver = get_ver();
fprintf('Version %s\n',echo_ver);
online=true;
    try
        
        fprintf('Checking for updates...\n');
        tmp=webread('http://sourceforge.net/projects/esp3/best_release.json',weboptions('ContentType','json'));
        
        if ispc()
            real_struct=tmp.platform_releases.windows;
        elseif ismac()
            real_struct=tmp.platform_releases.mac;
        elseif isunix()
            real_struct=tmp.platform_releases.linux;
        end
        
        if isempty(real_struct)
            real_struct=tmp.platform_releases.windows;
        end
        
        real_filename=real_struct.filename;
        last_ver=sscanf(real_filename,'/esp3_install_ver_%d.%d.%d.msi');
        curr_ver=sscanf(echo_ver,'%d.%d.%d');
        new_bool=last_ver>curr_ver;
        new_same_bool=last_ver>=curr_ver;
        
        new=0;
        
        if new_bool(1)>0
            new=1;
        elseif new_bool(2)>0&&new_same_bool(1)>0
            new=1;
        elseif new_bool(3)>0&&new_same_bool(2)>0&&new_same_bool(1)>0
            new=1;
        end
        
        if new>0
            
            QuestFig=new_echo_figure(main_figure,'units','pixels','position',[200 200 400 100],...
                'WindowStyle','modal','Visible','on','resize','off','tag','dlnewversion','Name','Update Available');
            bgcolor = num2cell([0.8 0.8 0.8]);
            
            % Create and display the text label
            labelStr = sprintf('<html>New version available! Download here: <a href="">%s</a></html>',real_struct.url);
            jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
            [hjLabel,~] = javacomponent(jLabel, [10,20,380,80], QuestFig);
            % Modify the mouse cursor when hovering on the label
            hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
            hjLabel.setBackground(java.awt.Color(bgcolor{:}));
            % Set the label's tooltip
            %hjLabel.setToolTipText(['Visit the ' real_struct.url ' website']);
            
            % Set the mouse-click callback
            set(hjLabel, 'MouseClickedCallback', @(h,e)web(real_struct.url, '-browser'))
            
        else
            disp_perso(main_figure,'ESP3 seems to be up to date...');
        end
    catch err
        online=false;
        print_errors_and_warnings([],'error',err);
        disp_perso(main_figure,'Could not check for updates online');
    end






end