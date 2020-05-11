function import_new_cmap_callback(~,~,main_figure)

cmaps_folder=fullfile(whereisEcho,'private','cmaps');
cpt_file=fullfile(cmaps_folder,'*.cpt');

[Filename,PathToFile]= uigetfile({cpt_file}, 'Pick .cpt_file(s)','MultiSelect','on');
if isempty(Filename)
    return;
end

if ~iscell(Filename)
    Filename={Filename};
end

for i=1:numel(Filename)
    try
        [cmap, lims, ticks, bfncol, ctable]=cpt_to_cmap(fullfile(PathToFile,Filename{i}));
%         B=bfncol(1,:);
%         F=bfncol(2,:);
%         N=bfncol(3,:);
        copyfile(fullfile(PathToFile,Filename{i}),cmaps_folder,'f');
        fprintf('Added %s\n',Filename{i});
    catch err
        print_errors_and_warnings([],'error',err);
        fprintf('Could not read colormap file: %s\n',fullfile(PathToFile,Filename{i}));
    end
end

create_menu(main_figure);
end