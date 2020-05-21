classdef test_esp3_cl < matlab.unittest.TestCase
    
    properties
        esp3_obj
    end
    
    methods(TestMethodSetup)
        function launchESP3(testCase)
            testCase.esp3_obj=EchoAnalysis();
            fprintf('Starting ESP3\n');
            testCase.addTeardown(@close,testCase.esp3_obj.main_figure);
        end
    end
    
    methods (Test)
        function open_test_files(testCase)
            
            file_path= fullfile(testCase.esp3_obj.app_path.test_folder.Path_to_folder,'files');
            
            if isfolder(fullfile(file_path,'echoanalysisfiles'))
                fprintf('Deleting echoanalysisfiles folder for tests files\n');
                rmdir(fullfile(file_path,'echoanalysisfiles'),'s');
            end
            if isfolder(fullfile(file_path,'bot_reg'))
                fprintf('Deleting bot_reg folder for tests files\n');
                rmdir(fullfile(file_path,'bot_reg'),'s');
            end
            
            if isfile(fullfile(file_path,'echo_logbook.db'))
                fprintf('Deleting logbook db for tests files\n');
                delete(fullfile(file_path,'echo_logbook.db'));
            end
            
            
            [file_list,~]=list_ac_files(file_path,1);
            
            n_files=numel(file_list);
            
            %             nb_files_max=10;
            %             idx_proc=randi(n_files,[1 nanmin(nb_files_max,n_files)]);
            %
            idx_proc=1:n_files;
            idx_proc=unique(idx_proc);
            file_list=file_list(idx_proc);
            
            fprintf(1,'Openning files: \n')
            cellfun(@(x) fprintf(1,'%s\n',x),file_list);
            
            output=open_file([],[],fullfile(file_path,file_list),testCase.esp3_obj.main_figure);
            
            
            testCase.verifyEqual(all(output), true, ...
                [sprintf('The following files were not successfully opened: \n') sprintf('%s\n',file_list{~output})]);
        end
        
        function run_scripts(testCase)
            script_path= fullfile(testCase.esp3_obj.app_path.test_folder.Path_to_folder,'scripts');
            
            PathToResults = fullfile(testCase.esp3_obj.app_path.test_folder.Path_to_folder,'esp3_results');
            
            f=dir(fullfile(script_path,'*.xml'));
            scripts_to_run = {f([f(:).isdir]==0).name};
            
            [~,surv_objs_out] = process_surveys(fullfile(script_path,scripts_to_run),...
                'origin','xml','gui_main_handle',testCase.esp3_obj.main_figure,'PathToResults',PathToResults,'update_display_at_loading',false);
            
            
            testCase.verifyEqual(numel(surv_objs_out)==numel(scripts_to_run), true, ...
                sprintf('It looks like not all scripts were able to be run.... You should now run the "compare_scripts_results" test'));
        end
        
        function compare_scripts_results(testCase)
            
            Path_esp3 = fullfile(testCase.esp3_obj.app_path.test_folder.Path_to_folder,'results');
            Path_ref = fullfile(testCase.esp3_obj.app_path.test_folder.Path_to_folder,'reference_results');
            
            f=dir(fullfile(Path_ref,'*_mbs_output.txt'));
            files = {f([f(:).isdir]==0).name};
            ref_files=fullfile(Path_ref,files);
            esp3_files=fullfile(Path_esp3,files);
            
            
            
            
            same=true(1,numel(esp3_files));
            diff_cell=cell(1,numel(esp3_files));
            surv_obj_cell=cell(1,numel(esp3_files));
            %fig=new_echo_figure([]);
            fig=[];
            for ii=1:numel(esp3_files)
                if isfile(esp3_files{ii})
                    fprintf('File %s:\n',esp3_files{ii});
                    [same(ii),diff_cell{ii},surv_obj_cell{ii},~]=check_diff(fig,esp3_files{ii},ref_files{ii},1);
                else
                    same(ii)=false;
                    diff_cell{ii}=[];
                end
            end
            testCase.verifyEqual(all(same), true, ...
                [sprintf('The following files did not contained similar results to previous runs:\n') sprintf('%s\n',esp3_files{~same})]);
            for ui=1:numel(same)
                if ~same(ui)&&~isempty(diff_cell{ui})
                    fprintf('\nDifferent results on files %s from script %s:\n',esp3_files{ui},surv_obj_cell{ui}.SurvInput.Infos.Script);
                    fprintf('%s\n',diff_cell{ui}{:});
                elseif ~same(ui)&&isempty(diff_cell{ui})
                    fprintf('No new results files for %s:\nYou might need to rerun the corresponding script\n',esp3_files{ui});
                end
            end
        end
        
        function compare_cw_calibration_results(testCase)
            
            cal_file = fullfile(testCase.esp3_obj.app_path.test_folder.Path_to_folder,'cw_calibration','tan1610-D20160826-T224922.raw');
            if isfile(cal_file)
                open_file([],[],cal_file,testCase.esp3_obj.main_figure);
                
                layers=get_esp3_prop('layers');
                [idx_lay,found]=layers.find_layer_idx_files(cal_file);
                
                if found
                    layer=layers(idx_lay);
                    layer.EnvData.Depth=25;
                    layer.EnvData.Salinity=35;
                    layer.EnvData.Temperature=11.8;
                    
                    [cal_cw,~]=TS_calibration_curves_func(testCase.esp3_obj.main_figure,layer,1:numel(layer.Transceivers));
                else
                    testCase.assertTrue(false,'Failed loading calibration file');
                    return;
                end
                
                cal_cw_ori.G0=[22.80 26.23 26.33 26.19 24.92];
                cal_cw_ori.SACORRECT=[-0.71 -0.62 -0.31 -0.33 -0.17];
                
                %cal_cw_ori.EQA=nan(1,numel(layer.Transceivers));
                %cal_cw_ori.AngleOffsetAlongship=nan(1,numel(layer.Transceivers));
                %cal_cw_ori.AngleOffsetAthwartship=nan(1,numel(layer.Transceivers));
                cal_cw_ori.BeamWidthAlongship=[10.6 7.0 6.4 6.3 6.4];
                cal_cw_ori.BeamWidthAthwartship=[10.9 7.1 6.6 6.5 6.3];
                %cal_cw_ori.RMS=nan(1,numel(layer.Transceivers));
                
                fnames=fieldnames(cal_cw_ori);
                
                same=true(numel(fnames),numel(layer.Transceivers));
                
                for uif=1:numel(fnames)
                    if isfield(cal_cw_ori,fnames{uif})
                        same(uif,:)=abs(cal_cw_ori.(fnames{uif})-cal_cw.(fnames{uif}))<0.05;
                    end
                end
                
                testCase.verifyEqual(all(same(:)),true, ...
                    [sprintf('The following results were disimilar results to previous calibration runs:\n') sprintf('%s\n',fnames{nansum(~same(1:2),2)>0})]);
                
                for it=1:numel(layer.Transceivers)
                    for uif=1:numel(fnames)
                        if ~same(uif,it)
                            fprintf('%s different for channel %s: %.2f instead of %.2f\n',fnames{uif},layer.ChannelID{it},cal_cw.(fnames{uif})(it),cal_cw_ori.(fnames{uif})(it));
                        end
                    end
                end
            else
                testCase.verifyEqual(false,true, ...
                    sprintf('Could not find Calibration file %s',cal_file));
            end
        end
        
        function test_algos(testCase)
            file_path= fullfile(testCase.esp3_obj.app_path.test_folder.Path_to_folder,'files');
            
            [files,~]=list_ac_files(file_path,1);
            
            n_files=numel(files);
            nb_files_max=5;
            
            idx_proc=randi(n_files,[1 nanmin(nb_files_max,n_files)]);
            
            idx_proc=unique(idx_proc);
            
            fff=fullfile(file_path,files(idx_proc));
            open_file([],[],fff,testCase.esp3_obj.main_figure);
            
            layers=testCase.esp3_obj.layers;
            
            [idx_lays,found]=layers.find_layer_idx_files(fff);
            al_names=list_algos();
            sucess=cell(numel(idx_lays),numel(al_names));
            load_bar_comp=getappdata(testCase.esp3_obj.main_figure,'Loading_bar');
            show_status_bar(testCase.esp3_obj.main_figure);
            pass=true;
            
            for ial=1:numel(al_names)
                ii=0;
                for ui=idx_lays
                    ii=ii+1;
                    if found(ii)
                        out_tmp=layers(ui).apply_algo(al_names{ial},'load_bar_comp',load_bar_comp);
                        sucess{ii,ial}=false(1,numel(out_tmp));
                        for ifi=1:numel(out_tmp)
                            sucess{ii,ial}(ifi)=out_tmp{ifi}.done;
                        end
                        pass=all(sucess{ial});
                    end
                end
            end
            
            hide_status_bar(testCase.esp3_obj.main_figure);
            update_display(testCase.esp3_obj.main_figure,1,1);
            testCase.verifyEqual(pass, true, ...
                'Error applying algorithms on files');
            
            for ial=1:numel(al_names)
                for uj=1:numel(idx_lays)
                    if any(~sucess{uj,ial})
                        fprintf('Could not apply %s to %s\n',al_names{ial},strjoin(layers(idx_lays(uj)).Filename,' and '));
                    end
                end
            end
            
            
        end
        
        
    end
end


