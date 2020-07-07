classdef survey_input_cl < handle
    properties
        
        Infos
        Options
        Cal
        Algos
        Regions_WC
        Snapshots
        
    end
    
    
    methods
        function surv_input_obj=survey_input_cl(varargin)
            
            p = inputParser;
            
            
            default_info=struct('Script','','XmlId','','Title','','Main_species','','Areas','','Voyage','','SurveyName','',...
                'Author','','Created','','Comments','');
            
            default_cal=struct('G0',25.10,'SACORRECT',0.0,'FREQ',38000,'EQA',-21);
            default_cal.CID={''};
            addParameter(p,'Infos',default_info);
            addParameter(p,'Cal',default_cal);
            addParameter(p,'Options',survey_options_cl);
            addParameter(p,'Algos',{});
            addParameter(p,'Regions_WC',{});
            addParameter(p,'Snapshots',{struct('Number',0,'Folder','','Stratum','','Type',{' '},'Design',' ','Cal',[])});
            parse(p,varargin{:});
            
            
            results=p.Results;
            props_infos=fieldnames(results.Infos);
            
            
            surv_input_obj.Infos=default_info;
            for i=1:length(props_infos)
                surv_input_obj.Infos.(props_infos{i})=results.Infos.(props_infos{i});
            end
            
            surv_input_obj.Options=results.Options;
            surv_input_obj.Algos=results.Algos;
            surv_input_obj.Cal=results.Cal;
            surv_input_obj.Regions_WC=results.Regions_WC;
            surv_input_obj.Snapshots=results.Snapshots;
            
        end
        
        function [snapshot_vec,type_vec,stratum_vec,transect_vec,reg_num_vec,files,regs,cells]=list_transects(surv_in_obj)
            snapshots=surv_in_obj.Snapshots;
            nb_trans=0;
            snapshot_vec=[];
            stratum_vec={};
            type_vec={};
            transect_vec=[];
            reg_num_vec=[];
            regs={};
            cells={};
            files={};
            
            for isn=1:length(snapshots)
                snap_num=snapshots{isn}.Number;
                type_snap=snapshots{isn}.Type;
                stratum=snapshots{isn}.Stratum;
                for ist=1:length(stratum)
                    strat_name=stratum{ist}.Name;
                    transects=stratum{ist}.Transects;
                    for itr=1:length(transects)
                        for itr2=1:numel(transects{itr}.number)
                            nb_trans=nb_trans+1;
                            trans_num=transects{itr}.number(itr2);
                            type_vec{nb_trans}=strjoin(type_snap,';');
                            snapshot_vec(nb_trans)=snap_num;
                            stratum_vec{nb_trans}=strat_name;
                            transect_vec(nb_trans)=trans_num;
                            files{nb_trans}=transects{itr}.files;
                            regs{nb_trans}=transects{itr}.Regions(:);
                            cells{nb_trans}=transects{itr}.Cells(:);
                            reg_num_vec(nb_trans)=length(transects{itr}.Regions);
                        end
                    end
                end
            end

             
            if nb_trans>0
                type_vec(cellfun(@isempty,type_vec))={' '};
                stratum_vec(cellfun(@isempty,stratum_vec))={' '};
            end
            
        end
        function delete(obj)
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
        
        function folders=list_data_folders(obj)
            folders={};
            for ui=1:numel(obj.Snapshots)
                folders=[folders obj.Snapshots{ui}.Folder];
            end
            folders=unique(folders);
        end
    end
end