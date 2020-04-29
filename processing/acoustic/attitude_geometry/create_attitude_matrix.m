function attitude_mat=create_attitude_matrix(Pitch,Roll,Yaw)
Yaw(isnan(Yaw))=0;
Roll(isnan(Roll))=0;
Pitch(isnan(Pitch))=0;

roll_mat=[[ 1 0 0 ];[0 cosd(Roll) -sind(Roll)];[0 sind(Roll) cosd(Roll)]];
pitch_mat=[[cosd(Pitch) 0 sind(Pitch)];[ 0 1 0 ];[-sind(Pitch) 0 cosd(Pitch)]];
yaw_mat=[[cosd(Yaw) -sind(Yaw) 0];[sind(Yaw)  cosd(Yaw) 0];[ 0 0 1 ]];

attitude_mat=yaw_mat*pitch_mat*roll_mat;
end