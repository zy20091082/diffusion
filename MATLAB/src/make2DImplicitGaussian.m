% % Andrew Rhodes
% December 2017
% make3DGaussianMatrix
%
% Builds the 2D discrete Gaussian
%
% input[]:
% input[]:
% input[]:
% input[]:
% input[]:
% input[]:
% input[]:
%
% output[G]:



function G = make2DImplicitGaussian(x, y, sigma, spacing, band, numsigmas, LimitFarPoints)

% Prob3D = chi2cdf(numsigma^2,dimension)

% Preferable that sigma < spacing

% sigma = 0.25;
% spacing = 0.5;


% if sigma == spacing
%     SpacingEqualSigma = true;
% end


% clc
% numsigmas = 4;
% sigma = 0.1
% spacing = 0.3
% LimitFarPoints=1

TotalSigma = numsigmas * sigma;
SpacingSigmaRatio =  ceil(TotalSigma / spacing);


vec1d = -SpacingSigmaRatio*spacing:spacing:SpacingSigmaRatio*spacing;


[xg,yg] = meshgrid(vec1d, vec1d);

weights = exp( - (xg.^2 + yg.^2 ) ./ (2*sigma^2) );
weights = reshape(weights, [],1);
weights = weights ./ sum(weights(:));


PTS = [reshape(xg,[],1),reshape(yg,[],1)]./spacing;
PTS = double(int16(PTS));

if LimitFarPoints
    TooFarPts = reshape(sqrt(xg.^2 + yg.^2 ) > TotalSigma,[],1);
    
    weights(TooFarPts) = [];
    PTS(TooFarPts,:) = [];
end


% Possibly could reduce the size of weights to only include points within a
% ball of radius 4*spacing, if sigma<spacing


Nx = length(x);
Ny = length(y);


StencilSize = length(weights);

Gi = repmat((1:length(band))',1, StencilSize);
Gj = zeros(size(Gi));
Gs = zeros(size(Gi));


[j,i] = ind2sub([Ny,Nx], band);

% tic
for c = 1 : StencilSize
    
    ii = i + PTS(c,2);
    jj = j + PTS(c,1);
    Gs(:,c) = weights(c);
    
    Gj(:,c) = sub2ind([Ny,Nx],jj,ii);

    
end
% toc

% Consruct the Gaussian kernel
G = sparse(Gi(:), Gj(:), Gs(:), length(band), Nx*Ny);


% Gout = G(:, setdiff(1:(Nx*Ny*Nz),Band));

if nnz(G) ~= nnz(G(:,band))
    disp('Lost some non-zero coefficients (from outside the outerband)')
end

G = G(:,band);


% Normalize the rows to unity after simplifying by band

Glength = length(G);

G = sparse(1:Glength,1:Glength, 1./sum(G,2)) * G;


end













