function [w]=TSCDE(x_train,y_train,x_test,y_test)
%
% Importance weigth estimation
%
% Estimating Importance weights from samples {(x_i,y_i)}_{i=1}^n
%
% Usage:
%       [w]=TSCDE(x_train,y_train,x_test,y_test)
%
% Input:
%    x_train:      d_x by n training sample matrix
%    y_train:      d_y by n training sample matrix
%    x_test:       d_x by n_test sample matrix
%    y_test:       d_y by n_test sample matrix
%    
% Output:
%    w:          weights
%   
%


ky_list=logspace(-1.5,1.5,9); % Candidates of Gaussian width
kx_list=logspace(-1.5,1.5,9); % Candidates of Gaussian width
lamda_list=logspace(-3,1,9); % Candidates of regularization parameter
delta_list=logspace(-3,1,9); % Candidates of regularization parameter
x_train_cv=x_train(1:length(x_train)/2); x_test_cv=x_test(1:length(x_train)/2);
y_train_cv=y_train(1:length(y_train)/2);n_cv=length(x_train_cv);n1_cv=length(x_test_cv);
xcv=[x_train_cv x_test_cv];
x_train=x_train(length(x_train)/2+1:end);x_test=x_test(length(x_test)/2+1:end);
ycv=[y_train_cv];y_train=y_train(length(y_train)/2+1:end);

 x=[x_train x_test];  
[d_x,n]=size(x_train);
[d_y,n]=size(y_train);
[d_x,n1]=size(x_test);
b=min(100,n+n1); % Number of kernel bases

  %%%%%%%%%%%%%%%% Choose Gaussian kernel centers 
  rand_index=randperm(n+n1);
  cl_x=x(:,rand_index(1:n+n1)); 
  rand_index=randperm(b);
  cl_y=y_train(:,rand_index(1:b));  
  
  V1_dist2=repmat(sum(x_train.^2,1),[n+n1 1])+repmat(sum(cl_x.^2,1)',[1 n])-2*cl_x'*x_train;% (lxn)
  V2_dist2=repmat(sum(y_train.^2,1),[b 1])+repmat(sum(cl_y.^2,1)',[1 n])-2*cl_y'*y_train;%(l1 x n)
  u_dist2=repmat(sum(x_test.^2,1),[n+n1 1])+repmat(sum(cl_x.^2,1)',[1 n1])-2*cl_x'*x_test;% (n+n1)x n1
  U_dist2=repmat(sum(cl_x.^2,1),[n+n1 1])+repmat(sum(cl_x.^2,1)',[1 n+n1])-2*cl_x'*cl_x;% (n+n1)x (n+n1)
  constr_dist2=repmat(sum(y_train.^2,1),[b 1])+repmat(sum(y_train(1:b).^2,1)',[1 n])-2*y_train(1:b)'*y_train;%(l1 x n)
  
  %%%%%%%%%%%%%%%%%% CV DATA %%%%%%%%%%%%%%%%%%%%%%%5
  V1_dist2_cv=repmat(sum(x_train_cv.^2,1),[n+n1 1])+repmat(sum(cl_x.^2,1)',[1 n_cv])-2*cl_x'*x_train_cv;% (lxn)
  V2_dist2_cv=repmat(sum(y_train_cv.^2,1),[b 1])+repmat(sum(cl_y.^2,1)',[1 n_cv])-2*cl_y'*y_train_cv;%(l1 x n)
  u_dist2_cv=repmat(sum(x_test_cv.^2,1),[n+n1 1])+repmat(sum(cl_x.^2,1)',[1 n1_cv])-2*cl_x'*x_test_cv;% (n+n1)x n1
  U_dist2_cv=repmat(sum(cl_x.^2,1),[n+n1 1])+repmat(sum(cl_x.^2,1)',[1 n+n1])-2*cl_x'*cl_x;% (n+n1)x (n+n1)
  X=[];iter=2;l2_dist=[];DIST=[];
  for out_index=1:length(ky_list)% outer loop  of ky and lamda
    ky=ky_list(out_index);lamda=lamda_list(out_index);out_index    
    for in_index=1:length(kx_list) %inner loop  of kx and delta
        kx=kx_list(in_index);delta=delta_list(in_index);   
        DIST=[];X1=[];
        for cv=1:iter          
      U=(sqrt(pi)*kx)^d_x*exp(-U_dist2/(4*kx^2));       
      phi_ucap=exp(-u_dist2/(2*kx^2));
      ucap=mean(phi_ucap,2);       
      phi_xu=exp(-V1_dist2/(2*kx^2));
      phi_yv=exp(-V2_dist2/(2*ky^2));
      V=(phi_xu*phi_yv')./n;%h      
      phi_constr=exp(-constr_dist2/(2*ky^2));
      constr_mat=mean(phi_constr,2);      
      H=V'*inv(U+delta*eye(n+n1))*V+lamda*eye(b);H=(H+H')/2;
      f_temp=-ucap'*inv(U+delta*eye(n+n1))*V;
      f=f_temp';
      Aeq=constr_mat';
      beq=1;
      lb=zeros(b,1);ub=inf;
      options = optimset('Algorithm','interior-point-convex');
      [x,fval,exitflag] = quadprog(H,f,[],[],Aeq,beq,lb,[],[],options); %adding options with interior-point convergence
       
      X1=[X1 x];
      %%%%%%%%%%%%%%% CV LOOP %%%%%%%%%%%%%%%%%
      U_cv=(sqrt(pi)*kx)^d_x*exp(-U_dist2_cv/(4*kx^2));       
      phi_ucap_cv=exp(-u_dist2_cv/(2*kx^2));
      ucap_cv=mean(phi_ucap_cv,2);       
      phi_xu_cv=exp(-V1_dist2_cv/(2*kx^2));
      phi_yv_cv=exp(-V2_dist2_cv/(2*ky^2));
      V_cv=(phi_xu_cv*phi_yv_cv')./n;%h      
      
      temp=l2_dist_est(x,U_cv,V_cv,ucap_cv,delta,lamda,n_cv,n1_cv,b);
      DIST=[DIST temp];  
      
      %%%%%%%%%%%%%%%%%%%
      temp=V1_dist2; V1_dist2=V1_dist2_cv; V1_dist2_cv=temp;
      temp=V2_dist2; V2_dist2=V2_dist2_cv; V2_dist2_cv=temp;
      temp=U_dist2; U_dist2=U_dist2_cv; U_dist2_cv=temp;
      temp=u_dist2; u_dist2=u_dist2_cv; u_dist2_cv=temp;
      
      %%%%%%%%%%%%%%END CV LOOP%%%%%%%%%%%
        end %cv loop
        l2_dist=[l2_dist mean(DIST)];X=[X mean(X1,2)];
    end % for inner loop
   end % for outer loop
  [val,ind]=min(l2_dist);
  alpha=X(:,ind);
  w=alpha'*phi_constr;
  end 
  

