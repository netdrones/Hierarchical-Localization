import os
import tqdm
import pycolmap
import argparse

from pathlib import Path
from hloc.utils import viz_3d
from hloc.visualization import plot_images, read_image
from hloc.localize_sfm import QueryLocalizer, pose_from_cluster
from hloc import extract_features, match_features, reconstruction, visualization, pairs_from_exhaustive

# Configs
matcher_conf = match_features.confs['superglue']
feature_conf = extract_features.confs['superpoint_aachen']
conf = {'estimation': {'ransac': {'max_error': 12}},
        'refinement': {'refine_focal_length': True, 'refine_extra_params': True}}

class ImageLocalizer:

    def __init__(self, recon_dir):

        # Load directories and images
        self.recon_dir = Path(recon_dir)
        self.sfm_dir = self.recon_dir / 'sfm'
        self.image_dir = self.recon_dir / 'images'
        self.matches = self.recon_dir / 'matches.h5'
        self.features = self.recon_dir / 'features.h5'
        self.sfm_pairs = self.recon_dir / 'pairs-sfm.txt'
        self.loc_pairs = self.recon_dir / 'pairs-loc.txt'
        self.model = pycolmap.Reconstruction(self.sfm_dir)
        self.images = [str(p.relative_to(self.image_dir)) for p in self.image_dir.iterdir()]
        self.registered_images = [self.model.images[i].name for i in self.model.reg_image_ids()]
        self.image_ids = [self.model.find_image_with_name(n).image_id for n in self.registered_images]

        # Initialize localizer model
        self.localizer = QueryLocalizer(self.model, conf)

    def localize_image(self, image, query_dir):

        # Extract features and match
        image = os.path.join(query_dir, image)
        query_dir = Path(query_dir)
        extract_features.main(feature_conf, query_dir, image_list=[image], feature_path=self.features, overwrite=True)
        pairs_from_exhaustive.main(self.loc_pairs, image_list=[image], ref_list=self.registered_images)
        match_features.main(matcher_conf, self.loc_pairs, features=self.features, matches=self.matches, overwrite=True)

        # Compute pose estimate
        camera = pycolmap.infer_camera_from_image(image)
        ret, log = pose_from_cluster(self.localizer, image, camera, self.image_ids, self.features, self.matches)
        pose = pycolmap.Image(tvec=ret['tvec'], qvec=ret['qvec'])
        return pose

def main(args):

    loc = ImageLocalizer(args.recon_dir)
    queries = os.listdir(args.query_dir)

    for img in queries:
        pose = loc.localize_image(img, args.query_dir)

if __name__ == '__main__':

    parser = argparse.ArgumentParser()

    parser.add_argument('--recon_dir', type=Path, required=True)
    parser.add_argument('--query_dir', type=Path, required=True)

    args = parser.parse_args()
    main(args)
