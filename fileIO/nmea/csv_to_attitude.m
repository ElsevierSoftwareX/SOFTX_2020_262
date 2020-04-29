function attitude_full=csv_to_attitude(PathToFile,FileName)
if PathToFile==0
    return;
end

att_struct=readtable(fullfile(PathToFile,FileName));
fields =att_struct.Properties.VariableNames;

if all(ismember({'Heading','Heave','Pitch','Roll','Time'},fields))
    attitude_full=attitude_nav_cl('Heading',att_struct.Heading,'Heave',att_struct.Heave,'Pitch',att_struct.Pitch,'Roll',att_struct.Roll,'Time',datenum(att_struct.Time));
elseif all(ismember({'Heading','Heave','Pitch','Roll','Abscissa'},fields))
    attitude_full=attitude_nav_cl('Heading',att_struct.Heading,'Heave',att_struct.Heave,'Pitch',att_struct.Pitch,'Roll',att_struct.Roll,'Time',datenum(att_struct.Abscissa));
elseif all(ismember({'pitch','roll','yaw','datetime'},fields))
    attitude_full=attitude_nav_cl('Yaw',att_struct.yaw,'Pitch',att_struct.pitch,'Roll',att_struct.roll,'Time',datenum(att_struct.Time));
else
    attitude_full=attitude_nav_cl.empty();
end
end