function [x_along,y_across,z]=angles_to_pos_single(Range,AlongAngle,AcrossAngle,...
    Heave,Pitch,Roll,Yaw,...
     RollOffset,...
    PitchOffset,...
   YawOffset,...
   AlongOffset,...
   AcrossOffset,...
   Zoffset)

attitude_mat=create_attitude_matrix(AlongAngle,AcrossAngle,0);
pos_in_trans=attitude_mat*[0;0;Range];

attitude_mat_2=create_attitude_matrix(PitchOffset,RollOffset,YawOffset);
pos_in_trans_right=attitude_mat_2*pos_in_trans;

attitude_mat_3=create_attitude_matrix(Pitch,Roll,Yaw);

pos_mat=attitude_mat_3*(pos_in_trans_right+[AlongOffset;AcrossOffset;Zoffset])-[0;0;Heave];

x_along=-pos_mat(1);
y_across=pos_mat(2);
z=pos_mat(3);

end