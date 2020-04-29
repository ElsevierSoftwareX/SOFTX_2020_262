

function [same,diff_cell,survey_obj_new,survey_obj_ref]=check_diff(fig,new_file,reference_file,reduced)

same=true;
diff_cell={};
survey_obj_new = load_mbs_results_v2(new_file);
survey_obj_ref = load_mbs_results_v2(reference_file);

newData=survey_obj_new.SurvOutput;
refData=survey_obj_ref.SurvOutput;

[~,new_file,~]=fileparts(new_file);
[~,reference_file,~]=fileparts(reference_file);

fn_main='stratumSum';
fn_unique={'snapshot' 'stratum'};
fn_comp = {'no_transects' 'abscf_mean' 'abscf_sd' 'abscf_wmean' 'abscf_var'};

[tmp,diff_cell_tmp]=compare_fields(fig,refData,newData,fn_main,fn_unique,fn_comp,reference_file,new_file);
same=same&&tmp;diff_cell=union(diff_cell,diff_cell_tmp,'stable');

fn_main='transectSum';
fn_unique={'snapshot' 'stratum' 'transect'};
fn_comp = {'dist' 'abscf' 'vbscf' 'mean_d' 'pings' 'av_speed' 'start_lat' 'start_lon' 'finish_lat' 'finish_lon'};

[tmp,diff_cell_tmp]=compare_fields(fig,refData,newData,fn_main,fn_unique,fn_comp,reference_file,new_file);
same=same&&tmp;diff_cell=union(diff_cell,diff_cell_tmp,'stable');

fn_main='slicedTransectSum';
fn_unique={'snapshot' 'stratum' 'transect'};
%fn_comp = {'slice_size' 'num_slices' 'latitude' 'longitude' 'slice_abscf' };
fn_comp = {'slice_size' 'num_slices' 'slice_abscf' };

[tmp,diff_cell_tmp]=compare_fields(fig,refData,newData,fn_main,fn_unique,fn_comp,reference_file,new_file);
same=same&&tmp;
diff_cell=union(diff_cell,diff_cell_tmp,'stable');

if reduced==0
    fn_main='regionSum';
    fn_unique={'snapshot' 'stratum' 'transect' 'region_id' 'ref'};
    fn_comp = {'good_pings' 'start_d' 'mean_d' 'finish_d' 'av_speed' 'vbscf' 'abscf'};
    
    [tmp,diff_cell_tmp]=compare_fields(fig,refData,newData,fn_main,fn_unique,fn_comp,reference_file,new_file);
    same=same&&tmp;diff_cell=union(diff_cell,diff_cell_tmp,'stable');
    
    fn_main='regionSumAbscf';
    fn_unique={'snapshot' 'stratum' 'transect' 'region_id' };
    %fn_comp = {'num_v_slices' 'transmit_start' 'latitude' 'longitude' 'column_abscf'};
    fn_comp = {'num_v_slices' 'transmit_start' 'column_abscf'};
    
    
    [tmp,diff_cell_tmp]=compare_fields(fig,refData,newData,fn_main,fn_unique,fn_comp,reference_file,new_file);
    same=same&&tmp;diff_cell=union(diff_cell,diff_cell_tmp,'stable');
    fn_main='regionSumVbscf';
    fn_unique={'snapshot' 'stratum' 'transect' 'region_id'};
    fn_comp = {'num_h_slices' 'num_v_slices' 'region_vbscf' 'vbscf_values'};
    
    [tmp,diff_cell_tmp]=compare_fields(fig,refData,newData,fn_main,fn_unique,fn_comp,reference_file,new_file);
    same=same&&tmp;diff_cell=union(diff_cell,diff_cell_tmp,'stable');
end

end


function [same,diff_cell]=compare_fields(fig,refData,newData,fn_main,fn_unique,fn_comp,reference_file,new_file)
diff_cell={};
same = true;
main_data_ref=refData.(fn_main);
main_data_new=newData.(fn_main);

unique_esp2=cell(numel(main_data_ref.(fn_unique{1})),numel(fn_unique));
unique_esp3=cell(numel(main_data_new.(fn_unique{1})),numel(fn_unique));
for ifi=1:numel(fn_unique)
    if iscell(main_data_new.(fn_unique{ifi}))
        unique_esp2(:,ifi)=main_data_ref.(fn_unique{ifi})(:);
        unique_esp3(:,ifi)=main_data_new.(fn_unique{ifi})(:);
    else
        unique_esp2(:,ifi)=cellfun(@num2str,num2cell(main_data_ref.(fn_unique{ifi})(:)),'un',0);
        unique_esp3(:,ifi)=cellfun(@num2str,num2cell(main_data_new.(fn_unique{ifi})(:)),'un',0);
    end
end

[~,idx_esp2,idx_esp3]=intersect(cell2table(unique_esp2,'VariableNames',fn_unique),cell2table(unique_esp3,'VariableNames',fn_unique));

if ~isempty(fig)
    clf(fig);
    ax=axes(fig,'nextplot','add','box','on','xgrid','on','ygrid','on');
else
    ax=[];
end

if any(idx_esp3)
    x_lab=cell(1,numel(idx_esp3));
    for ic=1:numel(fn_unique)
        data_new_unique=main_data_new.(fn_unique{ic})(idx_esp3);
        for il=1:numel(x_lab)
            if iscell(data_new_unique)
                x_lab{il}=[x_lab{il} sprintf('%s: %s ',fn_unique{ic},data_new_unique{il})];
            else
                x_lab{il}=[x_lab{il} sprintf('%s: %.0f ',fn_unique{ic},data_new_unique(il))];
            end
        end
    end
    
    for iui = 1:length(fn_comp)
        data_new=main_data_new.(fn_comp{iui})(idx_esp3);
        data_ref=main_data_ref.(fn_comp{iui})(idx_esp2);
        
        
        if ~isempty(fig)&&~isvalid(ax)
            ax=axes(fig,'nextplot','add','box','on','xgrid','on','ygrid','on');
        end
        
        if iscell(data_new)
            
            for id=1:numel(data_new)
                if all(data_new{id}(:)==0)&&(all(data_ref{id}(:)==0))
                    continue;
                end
                if isempty(data_new{id})
                    continue;
                end
                
                if strcmpi( fn_comp{iui},'vbscf_values')
                    x_esp_3=main_data_new.num_h_slices(idx_esp3(id));
                    y_esp_3=main_data_new.num_v_slices(idx_esp3(id));
                    
                    x_esp_2=main_data_ref.num_h_slices(idx_esp2(id));
                    y_esp_2=main_data_ref.num_v_slices(idx_esp2(id));
                    amap3=(reshape(data_new{id}(1:y_esp_3*x_esp_3),y_esp_3,x_esp_3)');
                    amap2=(reshape(data_ref{id}(1:y_esp_2*x_esp_2),y_esp_2,x_esp_2)');
                    if ~isempty(fig)
                        ax1=subplot(1,2,1);
                        imagesc(ax1,pow2db_perso(amap3),'alphadata',~isnan(amap3)&amap3>0);
                        set(ax1,'xtick',1:y_esp_3,'ydir','reverse');
                        ax2=subplot(1,2,2);
                        imagesc(ax2,pow2db_perso(amap2),'alphadata',~isnan(amap2)&amap2>0);
                        set(ax2,'xtick',1:y_esp_2,'ydir','reverse');
                        caxis(ax1,[-80 -45]);
                        caxis(ax2,[-80 -45]);
                        linkprop([ax1 ax2],'clim');
                        grid(ax1,'on');
                        grid(ax2,'on');
                        title(ax1,['New ' fn_comp{iui} ': ' x_lab{id}],'interpreter','none');
                        title(ax2,['Reference ' fn_comp{iui} ': ' x_lab{id}],'interpreter','none');
                        pause(0.5);
                        delete(ax1);
                        delete(ax2);
                    end
                    tmp=print_diff(data_new{id},data_ref{id},fn_main,fn_comp{iui});
                    if ~tmp
                        disp(x_lab{id});
                        diff_cell{numel(diff_cell)+1}=sprintf('%s: %s, %s',fn_main,fn_comp{iui},x_lab{id});
                    end
                    
                else
                    if ~isempty(fig)
                        cla(ax);
                        title(ax,[fn_comp{iui} ': ' x_lab{id}],'interpreter','none');
                        plot(ax,data_new{id},'-+r');
                        plot(ax,data_ref{id},'-ok');
                        legend(ax,sprintf('New: %s',new_file),sprintf('Ref: %s',reference_file),'interpreter','none');
                        set(ax,'xtick',1:length(data_new{id}),'XTickLabelRotation',0,'xticklabel',1:length(data_new{id}));
                        if length(data_new{id})>1
                            xlim(ax,[1 length(data_new{id})]);
                        end
                    end
                    tmp=print_diff(data_new{id},data_ref{id},fn_main,fn_comp{iui});
                    if ~tmp
                        disp(x_lab{id});
                        diff_cell{numel(diff_cell)+1}=sprintf('%s: %s, %s',fn_main,fn_comp{iui},x_lab{id});
                    end
                    
                    pause(0.5);
                end
                same=same&&tmp;
            end
        else
            if all(data_new(:)==0)&&(all(data_ref(:)==0))
                continue;
            end
            if ~isempty(fig)
                cla(ax);
                title(ax,fn_comp{iui},'interpreter','none');
                plot(ax,data_new,'-+r');
                plot(ax,data_ref,'-ok');
                legend(ax,sprintf('New: %s',new_file),sprintf('Ref: %s',reference_file),'interpreter','none');
                set(ax,'xtick',1:length(idx_esp3),'XTickLabelRotation',-45,'xticklabel',x_lab);
                if length(idx_esp3)>1
                    xlim(ax,[1 length(idx_esp3)]);
                end
            end
            tmp=print_diff(data_new,data_ref,fn_main,fn_comp{iui});
            if ~tmp
                diff_cell{numel(diff_cell)+1}=sprintf('%s: %s',fn_main,fn_comp{iui});
            end
            pause(0.5);
        end
        
        same=same&&tmp;

    end
    fprintf(1,'\n');
end
end

function same=print_diff(data_new,data_ref,fn_main,fn_comp)
same= true;
if nansum(nansum(data_ref))~=0
    idx_comp=abs(data_ref)>0;
    if numel(data_new)==numel(data_ref)
        diff_strata_mean =nansum(data_new(idx_comp)-data_ref(idx_comp))./nansum(data_ref(idx_comp))*100;
    else
        idx_comp_3=abs(data_new)>0;
        diff_strata_mean =(nansum(data_new(idx_comp_3))-nansum(data_ref(idx_comp)))./nansum(data_ref(idx_comp))*100;
    end
    
    if abs(diff_strata_mean) < 0.001
        fprintf(1, '%s %s : New results are on average the same as the reference\n',fn_main, fn_comp);
    else
        if diff_strata_mean > 0
            fprintf(1, '%s %s : New results are on average %2.4f%% more than the reference\n',fn_main, fn_comp, abs(diff_strata_mean));
        else
            fprintf(1, '%s %s : New results are on average %2.4f%% less than the reference\n',fn_main, fn_comp, abs(diff_strata_mean));
        end
    end
    
    if abs(diff_strata_mean)>0.5
        same=false;
        pause(0.5);
    end
else
    if nansum(data_new)==0
        fprintf(1, '%s %s : New results are on average the same as the reference (both NULLs)\n',fn_main, fn_comp);
    else
        fprintf(1, '%s %s : New results are on average %2.4f whereas the reference is NULL\n',fn_main, fn_comp, nansum(data_new));
        same =false;
    end
end
end