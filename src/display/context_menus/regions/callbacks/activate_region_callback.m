%% activate_region_callback.m
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
% * |obj|: TODO: write description and info on variable
% * |ID|: TODO: write description and info on variable
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
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function activate_region_callback(Unique_ID,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

if ~iscell(Unique_ID)
   Unique_ID={Unique_ID}; 
end

if ~ismember(curr_disp.CursorMode,{'Normal','Create Region','Zoom In','Zoom Out'})
    return;
end

[ac_data_col,ac_bad_data_col,in_data_col,in_bad_data_col,txt_col]=set_region_colors(curr_disp.Cmap);

[echo_obj,trans_obj_tot,~,~]=get_axis_from_cids(main_figure,union({'main' 'mini'},layer.ChannelID));
reg_uid=layer.get_layer_reg_uid();

for iax=1:length(echo_obj)
    reg_text=findobj(echo_obj.get_main_ax(iax),'Tag','region_text');
    if isempty(reg_text)
        continue;
    end
    reg_text(isempty(reg_text))=[];
    [uid_rem,id_rem]=setdiff({reg_text(:).UserData},reg_uid);
    for iuid=1:numel(uid_rem) 
        delete(findobj(echo_obj.get_main_ax(iax),'UserData',uid_rem{iuid}));
    end
    reg_text(id_rem)=[];
    
    set(reg_text,'color',txt_col,'FontWeight','Normal');
    trans_obj=trans_obj_tot(iax);

    if ~isempty(Unique_ID)
        iit=(ismember({reg_text(:).UserData},Unique_ID));
        
        set(reg_text(iit),'FontWeight','Bold');
    end
    
    for ireg=1:numel(trans_obj.Regions)
        
        if ismember(trans_obj.Regions(ireg).Unique_ID,Unique_ID)
            
            col=ac_data_col;
            switch trans_obj.Regions(ireg).Type
                case 'Data'
                    col=ac_data_col;
                case 'Bad Data'
                    col=ac_bad_data_col;
            end
        else
            switch trans_obj.Regions(ireg).Type
                case 'Data'
                    col=in_data_col;
                case 'Bad Data'
                    col=in_bad_data_col;
            end
        end
        
        reg_patch_ac=findobj(echo_obj.get_main_ax(iax),{'Tag','region'},...
            '-and','UserData',trans_obj.Regions(ireg).Unique_ID,'-and','Type','Polygon','-not','FaceColor',col);
        
        set(reg_patch_ac,'FaceColor',col,'EdgeColor',col);
        

    end
end



end








