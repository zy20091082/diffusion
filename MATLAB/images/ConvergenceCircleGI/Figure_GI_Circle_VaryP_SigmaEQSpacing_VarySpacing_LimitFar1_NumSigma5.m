% Andrew Rhodes
% ASEL
% March 2018

% Diffusion accuracy comparison for a signal on a sphere.


close all
clear
clc

addpath('../../src/')
ProjectRoot = setupprojectpaths; % Additional Paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% User Defined Criteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MCspacing = [0.25, 0.1, 0.05, 0.025, 0.01, 0.005, 0.0025, 0.001];

MCporder = [1, 2, 3, 4, 5, 6, 7];

MCError = zeros(length(MCspacing), 2, length(MCporder));
MCErrorAll = cell(length(MCspacing), length(MCporder));


for MCp = 1 : length(MCporder)
    
    for MCs = 1 : length(MCspacing)
        
        
        clearvars -except MCspacing MCs MCp MCError MCErrorAll MCporder ProjectRoot
        spacing = MCspacing(MCs)
        porder = MCporder(MCp)
        
        
        alpha = 1;
        % porder = 9;
        dim = 2;
        % spacing = 0.01;
        % sigma <= spacing
        sigma = spacing;
        numsigmas = 5;
        LimitFarPoints = 1;

        if spacing > sigma
            bandwidth = 1.002*spacing*sqrt((dim-1)*((porder+1)/2)^2 + (((numsigmas*sigma)/spacing+(porder+1)/2)^2));
        else
            bandwidth = 1.002*numsigmas*sigma*sqrt((dim-1)*((porder+1)/2)^2 + (((numsigmas*sigma)/spacing+(porder+1)/2)^2));
        end
        ShowPlot = 0;
        NumCirclePoints = 1000;
        
        % tauImplicit = spacing / 8;
        % MaxTauImplicit = 1/spacing;
        NumSteps = round(1/spacing); % 5000 ; %
        
        ExactSignal = @(sigma, theta) exp(-sigma^2/2)*cos(theta) + exp(-9*sigma^2/2)*sin(3*theta);
%         ExactSignal = @(sigma, theta) exp(-sigma^2/2)*cos(theta);


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Make the Circle and Signal
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        Theta = linspace(0, 2*pi, NumCirclePoints)';
        
        Radius = ones(size(Theta));
        [xp,yp] = pol2cart(Theta, Radius);
        Circle.Location(:,1) = xp(:);
        Circle.Location(:,2) = yp(:);
        Circle.LocationCount = length(Circle.Location);
        
        
        SignalOriginal = ExactSignal(0, Theta);
        
        Circle.Signal = SignalOriginal;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Setup File Name Directions
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        FileLocationCPGauss = strcat(ProjectRoot,'/models/Circle/CPGauss/');
        FileNameCP = strcat('CP','_NumPoints',num2str(NumCirclePoints),'_p',num2str(porder),'_s',num2str(spacing),'_NumSigma',num2str(numsigmas),'.mat');
        FileNameDIST = strcat('DIST','_NumPoints',num2str(NumCirclePoints),'_p',num2str(porder),'_s',num2str(spacing),'_NumSigma',num2str(numsigmas),'.mat');
        
        FileNameEcp = strcat('Ecp','_NumPoints',num2str(NumCirclePoints),'_p',num2str(porder),'_s',num2str(spacing),'_NumSigma',num2str(numsigmas),'.mat');
        FileNameEplot = strcat('Eplot','_NumPoints',num2str(NumCirclePoints),'_p',num2str(porder),'_s',num2str(spacing),'_NumSigma',num2str(numsigmas),'.mat');
        FileNameGCart = strcat('GCart','_NumPoints',num2str(NumCirclePoints),'_p',num2str(porder),'_s',num2str(spacing),'_NumSigma',num2str(numsigmas),'_LimitFar',num2str(LimitFarPoints),'.mat');
        FileNameG = strcat('G','_NumPoints',num2str(NumCirclePoints),'_p',num2str(porder),'_s',num2str(spacing),'_NumSigma',num2str(numsigmas),'_LimitFar',num2str(LimitFarPoints),'.mat');
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Construct the Laplace Beltrami
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        MinPoint = min(Circle.Location) - bandwidth - ceil(numsigmas * sigma);
        MaxPoint = max(Circle.Location) + bandwidth + ceil(numsigmas * sigma);
        
        % MinPoint = round(min(Circle.Location(:,1)) - bandwidth, 1);
        % MaxPoint = round(max(Circle.Location(:,1)) + bandwidth, 1);
        
        
        x1d = (MinPoint(1):spacing:MaxPoint(1))';
        y1d = (MinPoint(2):spacing:MaxPoint(2))';
        
        [GridX, GridY] = meshgrid(x1d, y1d);
        
%         if ~exist( fullfile(FileLocationCPGauss, FileNameCP), 'file') || ~exist( fullfile(FileLocationCPGauss, FileNameDIST), 'file')
            [CP(:,1), CP(:,2), DIST] = cpCircle(GridX(:), GridY(:));
           
%             save(fullfile(FileLocationCPGauss, FileNameCP), 'CP', '-v7.3')
%             save(fullfile(FileLocationCPGauss, FileNameDIST), 'DIST', '-v7.3')
%         else
%             load(fullfile(FileLocationCPGauss, FileNameCP), 'CP')
%             load(fullfile(FileLocationCPGauss, FileNameDIST), 'DIST')
%         end
        
        
        band = find(abs(DIST) <= bandwidth);
        
        CP = CP(band,:);
        
        GridXBand = GridX(band);
        GridYBand = GridY(band);
        
        
        [CPTheta, CPr] = cart2pol(GridXBand,GridYBand);
        
        
        CPSignal = ExactSignal(0, CPTheta);
        
        
%         if ~exist( fullfile(FileLocationCPGauss, FileNameEcp), 'file') || ~exist( fullfile(FileLocationCPGauss, FileNameEplot), 'file') || ~exist( fullfile(FileLocationCPGauss, FileNameGCart), 'file') || ~exist( fullfile(FileLocationCPGauss, FileNameG), 'file')

            Ecp = interp2_matrix(x1d, y1d, CP(:,1), CP(:,2), porder, band);

            Eplot = interp2_matrix(x1d, y1d, Circle.Location(:,1), Circle.Location(:,2), porder, band);

    %         % G = make3DImplicitGaussian(y1d, x1d, z1d, sigma, spacing, band, 4, 1);
            GCart = make2DImplicitGaussian(x1d, y1d, sigma, spacing, band, numsigmas, LimitFarPoints);

            % GE = diag(G) + (G - diag(G))*Ecp;
            G = GCart*Ecp;

%             save(fullfile(FileLocationCPGauss, FileNameEcp), 'Ecp', '-v7.3')
%             save(fullfile(FileLocationCPGauss, FileNameEplot), 'Eplot', '-v7.3')
%             save(fullfile(FileLocationCPGauss, FileNameGCart), 'GCart', '-v7.3')
%             save(fullfile(FileLocationCPGauss, FileNameG), 'G', '-v7.3')
            
%         else
%             
%             load(fullfile(FileLocationCPGauss, FileNameEcp))
%             load(fullfile(FileLocationCPGauss, FileNameEplot))
%             load(fullfile(FileLocationCPGauss, FileNameGCart))
%             load(fullfile(FileLocationCPGauss, FileNameG))
%             
%         end
        
        
        % Gaussian Method
        % MinPoint = round(min(PointCloud.Location) - bandwidth - 2*spacing, 1);
        % MaxPoint = round(max(PointCloud.Location) + bandwidth + 2*spacing, 1);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Scale Parameter Estimation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        ScaleParameter = findScaleParamter(sigma, alpha, NumSteps, 'natural', '2d');
        
        % ScaleParameter = zeros(NumSteps,1);
        %
        % for i = 1 : NumSteps
        %
        %     ScaleParameter(i+1,1) = sqrt(i)*sigma;
        %
        % end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Perform Diffusion
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Signal = zeros(length(CPSignal), NumSteps);
        % Signal(:,1) = CPSignal;
        Signal = CPSignal;
        
        % SignalAtVertex = zeros(Circle.LocationCount, NumSteps);
        % SignalAtVertex(:,1) = SignalOriginal;
        SignalAtVertex = SignalOriginal;
        
        WaitBar = waitbar(0, sprintf('Implicit Euler Diffusion %i of %i', 0, NumSteps-1));
        AbsErr = zeros(NumSteps,1);
        
        if ShowPlot
            figure(1)
        end
        for i = 1 : NumSteps - 1
            
            %     Signal(:,i+1) = GE * Signal(:,i);
            SignalNew = G * Signal;
            
            
            %     SignalAtVertex(:,i+1) = Eplot * Signal(:,i+1);
            SignalAtVertex = Eplot * SignalNew;
            
            Truth = ExactSignal( ScaleParameter(i+1,1), Theta);
            AbsErr(i+1,1) = norm(Truth - SignalAtVertex, inf);
            
            if ShowPlot 
                clf
                plot(Theta, SignalOriginal,'k')
                hold on
                plot(Theta, Truth, 'g-')
                plot(Theta, SignalAtVertex, 'r--')                
                legend('Original', 'Truth', 'Numerical')
            end
                
            Signal = SignalNew;
            
            waitbar(i/NumSteps, WaitBar, sprintf('Implicit Euler Diffusion %i of %i', i, NumSteps-1));
        end
        
        waitbar(i/NumSteps, WaitBar, sprintf('Diffusion Complete'));
        close(WaitBar)
        if ShowPlot
            close(figure(1))
        end
        
        
        MCError(MCs, 1:2, MCp) = [NumSteps, AbsErr(NumSteps - 1)];
        MCErrorAll{MCs, MCp} = [(1:NumSteps)', AbsErr];
        
    end
end

close all




% figure(2)
% loglog(MCError(:,1), MCError(:,2),'bd-')
% hold on
% logx = [100,10000];
% logy = (10e-1).*logx.^(-2);
% loglog(logx, logy,'k-')
%
%
%
%
% figure(3)
% for i = 1 : length(MCErrorAll)
%     loglog(MCErrorAll{i,1}(:,1), MCErrorAll{i,1}(:,2))
%     hold on
% end
% % loglog(1:NumStepsImplicit, AbsErr)
% xlabel('Iteration Number')
% ylabel('Absolute Error')
%
% logx = [10,1000];
% logy = (10e-11).*logx.^(1);
% loglog(logx, logy,'k-')




% MCErrorAll{MCs, MCp} = [(1:NumSteps)', AbsErr];


colors = ['k','b','c','k','m','g','r'];
shapes = {'','','p','s','o','*','+'};
lin  = {':','-.','-','-','--','-.',':'};
msizes = [8, 8, 8, 17, 14, 12, 8];



% colors = ['k','b','r','c','m','g','k'];
% shapes = ['.','^','.','*','+','o','s'];
% lin  = {':','-','-','-','-.',':','--'};
% msizes = [8, 8, 8, 8, 10, 12, 15];

Points = zeros(size(MCErrorAll,1),2, size(MCErrorAll,2));
for j = 1 : size(MCErrorAll,2)
    for i = 1 : size(MCErrorAll,1)
        Points(i,1:2,j) = [MCErrorAll{i,j}(end,1), MCErrorAll{i,j}(end,2)];
    end
end


figure('units','normalized','outerposition',[0 0 1 1])
for i = 1 : size(Points,3)
    loglog( Points(:,1,i), Points(:,2,i), strcat(colors(i), shapes{i}, lin{i}), 'linewidth', 3, 'markersize', msizes(i) )
    hold on
end


% % % % 3rd order line
logx = [3,10];
logy = (10e-2).*logx.^(-3);
loglog(logx, logy,'k-','linewidth',3)

xl=get(gca,'XLim');
yl=get(gca,'YLim');
text1 = text(2.5,10*10^(-4),'$3^{rd}$ Order','Interpreter','latex');
set(text1,'Rotation',-35)
set(text1,'FontSize',50)


% % % % 2nd order line
logx = [100,1000];
logy = (10*10^(-0.2)).*logx.^(-2);
loglog(logx, logy,'k-','linewidth',3)

text2 = text(200,10*10^(-4.5),'$2^{nd}$ Order','Interpreter','latex');
set(text2,'Rotation',-25)
set(text2,'FontSize',50)



% % % % 1st order line
logx = [100,1000];
logy = (10*10^(-0.5)).*logx.^(-1);
loglog(logx, logy,'k-','linewidth',3)

text3 = text(200,10*10^(-2.5),'$1^{st}$ Order','Interpreter','latex');
set(text3,'Rotation',-12)
set(text3,'FontSize',50)


xlabel('N')
ylabel('$\| $error$ \|_{\infty}$','Interpreter','latex')
ax = gca;
ax.XAxis.FontSize = 50;
ax.YAxis.FontSize = 50;


xlim([10*10^(-0.75) 10*10^(2.5)])


xticks([10e0 10e1 10e2 10e3])
yticks([10e-10, 10e-8, 10e-6, 10e-4, 10e-2, 10e0, 10e2, 10e4])
yticklabels({'10e-10','10e-8','10e-6','10e-4', '10e-2', '10e0', '10e2', '10e4'})

hleg = legend('p=1','p=2','p=3','p=4','p=5','p=6','p=7');
set(hleg, 'position', [0.82 0.63 0.07 0.2], 'FontSize', 35)












