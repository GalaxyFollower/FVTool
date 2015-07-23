function [M, RHS, Mx, My, Mz, RHSx, RHSy, RHSz] = ...
    convectionTvdTermCylindrical3D(MeshStructure, u, phi, FL)
% This function uses the TVD scheme to discretize a 3D
% convection term in the form \grad (u \phi) where u is a face vactor
% It also returns the x and y parts of the matrix of coefficient.
% 
% SYNOPSIS:
%   
% 
% PARAMETERS:
%   
% 
% RETURNS:
%   
% 
% EXAMPLE:
% 
% SEE ALSO:
%     

%{
Copyright (c) 2012, 2013, Ali Akbar Eftekhari
All rights reserved.

Redistribution and use in source and binary forms, with or 
without modification, are permitted provided that the following 
conditions are met:

    *   Redistributions of source code must retain the above copyright notice, 
        this list of conditions and the following disclaimer.
    *   Redistributions in binary form must reproduce the above 
        copyright notice, this list of conditions and the following 
        disclaimer in the documentation and/or other materials provided 
        with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%}

% extract data from the mesh structure
G = MeshStructure.numbering;
Nxyz = MeshStructure.numberofcells;
Nr = Nxyz(1); Ntetta = Nxyz(2); Nz = Nxyz(3);
d = MeshStructure.cellsize;
dx = d(1); dtetta = d(2); dz = d(3);
rp = repmat(MeshStructure.cellcenters.x', 1, Ntetta, Nz);
rf = repmat(MeshStructure.facecenters.x', 1, Ntetta, Nz);
psiX_p = zeros(Nr+1,Ntetta,Nz);
psiX_m = zeros(Nr+1,Ntetta,Nz);
psiY_p = zeros(Nr,Ntetta+1,Nz);
psiY_m = zeros(Nr,Ntetta+1,Nz);
psiZ_p = zeros(Nr,Ntetta,Nz+1);
psiZ_m = zeros(Nr,Ntetta,Nz+1);

% define the vectors to stores the sparse matrix data
iix = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);	
jjx = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);	
sx = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);	
iiy = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);
jjy = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);
sy = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);
iiz = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);
jjz = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);
sz = zeros(3*(Nr+2)*(Ntetta+2)*(Nz+2),1);
mnx = Nr*Ntetta*Nz;	mny = Nr*Ntetta*Nz;   mnz = Nr*Ntetta*Nz;

% extract the velocity data 
% note: size(ux) = [1:m+1, 1:n] and size(uy) = [1:m, 1:n+1]
ux = u.xvalue;
uy = u.yvalue;
uz = u.zvalue;

% calculate the upstream to downstream gradient ratios for u>0 (+ ratio)
% x direction
dphiX_p = phi(2:Nr+2, 2:Ntetta+1, 2:Nz+1)-phi(1:Nr+1, 2:Ntetta+1, 2:Nz+1);
rX_p = dphiX_p(1:end-1,:,:)./fsign(dphiX_p(2:end,:,:));
psiX_p(2:Nr+1,:,:) = 0.5*FL(rX_p).* ...
    (phi(3:Nr+2,2:Ntetta+1,2:Nz+1)-phi(2:Nr+1,2:Ntetta+1,2:Nz+1));
psiX_p(1,:,:) = 0; % left boundary
% y direction
dphiY_p = phi(2:Nr+1, 2:Ntetta+2, 2:Nz+1)-phi(2:Nr+1, 1:Ntetta+1, 2:Nz+1);
rY_p = dphiY_p(:,1:end-1,:)./fsign(dphiY_p(:,2:end,:));
psiY_p(:,2:Ntetta+1,:) = 0.5*FL(rY_p).* ...
    (phi(2:Nr+1,3:Ntetta+2,2:Nz+1)-phi(2:Nr+1, 2:Ntetta+1,2:Nz+1));
psiY_p(:,1,:) = 0; % Bottom boundary
% z direction
dphiZ_p = phi(2:Nr+1, 2:Ntetta+1, 2:Nz+2)-phi(2:Nr+1, 2:Ntetta+1, 1:Nz+1);
rZ_p = dphiZ_p(:,:,1:end-1)./fsign(dphiZ_p(:,:,2:end));
psiZ_p(:,:,2:Nz+1) = 0.5*FL(rZ_p).* ...
    (phi(2:Nr+1,2:Ntetta+1,3:Nz+2)-phi(2:Nr+1,2:Ntetta+1,2:Nz+1));
psiZ_p(:,:,1) = 0; % Back boundary

% calculate the upstream to downstream gradient ratios for u<0 (- ratio)
% x direction
rX_m = dphiX_p(2:end,:,:)./fsign(dphiX_p(1:end-1,:,:));
psiX_m(1:Nr,:,:) = 0.5*FL(rX_m).* ...
    (phi(1:Nr, 2:Ntetta+1, 2:Nz+1)-phi(2:Nr+1, 2:Ntetta+1, 2:Nz+1));
psiX_m(Nr+1,:,:) = 0; % right boundary
% y direction
rY_m = dphiY_p(:,2:end,:)./fsign(dphiY_p(:,1:end-1,:));
psiY_m(:,1:Ntetta,:) = 0.5*FL(rY_m).* ...
    (phi(2:Nr+1,1:Ntetta,2:Nz+1)-phi(2:Nr+1,2:Ntetta+1,2:Nz+1));
psiY_m(:,Ntetta+1,:) = 0; % top boundary
% z direction
rZ_m = dphiZ_p(:,:,2:end)./fsign(dphiZ_p(:,:,1:end-1));
psiZ_m(:,:,1:Nz) = 0.5*FL(rZ_m).* ...
    (phi(2:Nr+1,2:Ntetta+1,1:Nz)-phi(2:Nr+1,2:Ntetta+1,2:Nz+1));
psiZ_m(:,:,Nz+1) = 0; % front boundary
% reassign the east, west, north, and south velocity vectors for the 
% code readability
ue = ux(2:Nr+1,:,:);		uw = ux(1:Nr,:,:);
vn = uy(:,2:Ntetta+1,:);     vs = uy(:,1:Ntetta,:);
wf = uz(:,:,2:Nz+1);     wb = uz(:,:,1:Nz);
re = rf(2:Nr+1,:,:);         rw = rf(1:Nr,:,:);

% find the velocity direction for the upwind scheme
ue_min = min(ue,0);	ue_max = max(ue,0);
uw_min = min(uw,0);	uw_max = max(uw,0);
vn_min = min(vn,0);	vn_max = max(vn,0);
vs_min = min(vs,0);	vs_max = max(vs,0);
wf_min = min(wf,0);	wf_max = max(wf,0);
wb_min = min(wb,0);	wb_max = max(wb,0);

% calculate the coefficients for the internal cells
AE = re.*ue_min./(dx*rp);
AW = -rw.*uw_max./(dx*rp);
AN = vn_min./(dtetta*rp);
AS = -vs_max./(dtetta*rp);
AF = wf_min/dz;
AB = -wb_max/dz;
APx = (re.*ue_max-rw.*uw_min)./(dx*rp);
APy = (vn_max-vs_min)./(dtetta*rp);
APz = (wf_max-wb_min)/dz;

% Also correct for the boundary cells (not the ghost cells)
% Left boundary:
APx(1,:,:) = APx(1,:,:)-rw(1,:,:).*uw_max(1,:,:)./(2*rp(1,:,:)*dx);   AW(1,:,:) = AW(1,:,:)/2;
% Right boundary:
AE(end,:,:) = AE(end,:,:)/2;    APx(end,:,:) = APx(end,:,:)+re(end,:,:).*ue_min(end,:,:)./(2*dx*rp(end,:,:));
% Bottom boundary:
APy(:,1,:) = APy(:,1,:)-vs_max(:,1,:)./(2*dtetta*rp(:,1,:));   AS(:,1,:) = AS(:,1,:)/2;
% Top boundary:
AN(:,end,:) = AN(:,end,:)/2;    APy(:,end,:) = APy(:,end,:)+vn_min(:,end,:)./(2*dtetta*rp(:,end,:));
% Back boundary:
APz(:,:,1) = APz(:,:,1)-wb_max(:,:,1)/(2*dz);   AB(:,:,1) = AB(:,:,1)/2;
% Front boundary:
AF(:,:,end) = AF(:,:,end)/2;    APz(:,:,end) = APz(:,:,end) + wf_min(:,:,end)/(2*dz);

AE = reshape(AE,mnx,1);
AW = reshape(AW,mnx,1);
AN = reshape(AN,mny,1);
AS = reshape(AS,mny,1);
AF = reshape(AF,mnz,1);
AB = reshape(AB,mnz,1);
APx = reshape(APx,mnx,1);
APy = reshape(APy,mny,1);
APz = reshape(APz,mnz,1);

% build the sparse matrix based on the numbering system
rowx_index = reshape(G(2:Nr+1,2:Ntetta+1,2:Nz+1),mnx,1); % main diagonal x
iix(1:3*mnx) = repmat(rowx_index,3,1);
rowy_index = reshape(G(2:Nr+1,2:Ntetta+1,2:Nz+1),mny,1); % main diagonal y
iiy(1:3*mny) = repmat(rowy_index,3,1);
rowz_index = reshape(G(2:Nr+1,2:Ntetta+1,2:Nz+1),mnz,1); % main diagonal z
iiz(1:3*mnz) = repmat(rowz_index,3,1);
jjx(1:3*mnx) = [reshape(G(1:Nr,2:Ntetta+1,2:Nz+1),mnx,1); reshape(G(2:Nr+1,2:Ntetta+1,2:Nz+1),mnx,1); reshape(G(3:Nr+2,2:Ntetta+1,2:Nz+1),mnx,1)];
jjy(1:3*mny) = [reshape(G(2:Nr+1,1:Ntetta,2:Nz+1),mny,1); reshape(G(2:Nr+1,2:Ntetta+1,2:Nz+1),mny,1); reshape(G(2:Nr+1,3:Ntetta+2,2:Nz+1),mny,1)];
jjz(1:3*mnz) = [reshape(G(2:Nr+1,2:Ntetta+1,1:Nz),mnz,1); reshape(G(2:Nr+1,2:Ntetta+1,2:Nz+1),mnz,1); reshape(G(2:Nr+1,2:Ntetta+1,3:Nz+2),mnz,1)];
sx(1:3*mnx) = [AW; APx; AE];
sy(1:3*mny) = [AS; APy; AN];
sz(1:3*mnz) = [AB; APz; AF];

% calculate the TVD correction term
div_x = -(1./(dx*rp)).*(re.*(ue_max.*psiX_p(2:Nr+1,:,:)+ue_min.*psiX_m(2:Nr+1,:,:))- ...
              rw.*(uw_max.*psiX_p(1:Nr,:,:)+uw_min.*psiX_m(1:Nr,:,:)));
div_y = -(1./(dtetta*rp)).*((vn_max.*psiY_p(:,2:Ntetta+1,:)+vn_min.*psiY_m(:,2:Ntetta+1,:))- ...
              (vs_max.*psiY_p(:,1:Ntetta,:)+vs_min.*psiY_m(:,1:Ntetta,:)));
div_z = -(1/dz)*((wf_max.*psiZ_p(:,:,2:Nz+1)+wf_min.*psiZ_m(:,:,2:Nz+1))- ...
              (wb_max.*psiZ_p(:,:,1:Nz)+wb_min.*psiZ_m(:,:,1:Nz)));
          
% define the RHS Vector
RHS = zeros((Nr+2)*(Ntetta+2)*(Nz+2),1);
RHSx = zeros((Nr+2)*(Ntetta+2)*(Nz+2),1);
RHSy = zeros((Nr+2)*(Ntetta+2)*(Nz+2),1);
RHSz = zeros((Nr+2)*(Ntetta+2)*(Nz+2),1);

% assign the values of the RHS vector
row_index = rowx_index;
RHS(row_index) = reshape(div_x+div_y+div_z,Nr*Ntetta*Nz,1);
RHSx(rowx_index) = reshape(div_x,Nr*Ntetta*Nz,1);
RHSy(rowy_index) = reshape(div_y,Nr*Ntetta*Nz,1);
RHSz(rowz_index) = reshape(div_z,Nr*Ntetta*Nz,1);

% build the sparse matrix
kx = 3*mnx;
ky = 3*mny;
kz = 3*mnz;
Mx = sparse(iix(1:kx), jjx(1:kx), sx(1:kx), (Nr+2)*(Ntetta+2)*(Nz+2), (Nr+2)*(Ntetta+2)*(Nz+2));
My = sparse(iiy(1:ky), jjy(1:ky), sy(1:ky), (Nr+2)*(Ntetta+2)*(Nz+2), (Nr+2)*(Ntetta+2)*(Nz+2));
Mz = sparse(iiz(1:kz), jjz(1:kz), sz(1:kz), (Nr+2)*(Ntetta+2)*(Nz+2), (Nr+2)*(Ntetta+2)*(Nz+2));
M = Mx + My + Mz;

end

function phi_out = fsign(phi_in)
% This function checks the value of phi_in and assigns an eps value to the
% elements that are less than or equal to zero, while keeping the signs of
% the nonzero elements
    phi_out = (abs(phi_in)>=eps).*phi_in+eps*(phi_in==0)+eps*(abs(phi_in)<eps).*sign(phi_in);
end