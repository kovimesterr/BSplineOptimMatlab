%% Testing fastnullad + VarPro on ECG signals

addpath('./VarPro');
addpath('./FastNullad');

load('./Records/record117','beats');
load('./Results/InitRandKnot117','knots0');

%Parameters
Nkn=20; %Number of knots.
Nit=20; %Number of iterations of VarPro.
options = optimset('lsqnonlin');
options = optimset(options,'MaxIter',Nit);
options = optimset(options,'Display','off');

knotsVarPro=zeros(Nkn,length(beats));
prdnullad0=zeros(1,length(beats));
prdnullad3=zeros(1,length(beats));
prdVarPro=zeros(1,length(beats));

for i=1:1:length(beats)
    display(sprintf('Processing signal %d of %d',i,length(beats))); 
    x=(1:1:length(beats{i}))';
    y=preserve(x,beats{i});
    %Computing random initial knots.
    [c,aprx]=bspline_coeffs(y,knots0(:,i),4,false);
    prdnullad3(i)=norm(y-aprx')/norm(y-mean(y))*100;
    %Improving initial knots by VarPro.
    order=4; x=1:length(y); w=ones(size(y)); show=false; 
    ada=@(alpha) ada_bspline(order,x,y,alpha,show);    
    initalpha=reshape(knots0(:,i),length(knots0(:,i)),1);
    initalpha=initalpha(2:end-1); %boundary knots cannot be variable.
    n=length(initalpha)-1 + (order-1); %(number of knots)-1 + (degree of B-splines)
    %Knots should be valid sample indices, e.g., they are integers from the interval [1,length(beat)].
    lb=ones(length(initalpha),1)+1; 
    ub=length(beats{i})*ones(length(initalpha),1)-1;
    [alpha, c, wresid, wresid_norm, y_est, Regression] = ...
    varpro(y, w, initalpha, n, ada, lb, ub, options);
    knotsVarPro(:,i)=[knots0(1,i); alpha; knots0(end,i)];
    [c,aprxvarpro]=bspline_coeffs(y,knotsVarPro(:,i),4,show);
    prdVarPro(i)=norm(y-aprxvarpro')/norm(y-mean(y))*100;    
end
save('ResultsECGVarProRand117.mat','knots0','knotsVarPro','prdnullad3','prdVarPro');