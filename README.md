# RGBD-3DGS-SLAM
RGBD-3DGS-SLAM is a sophisticated SLAM system that employs 3D Gaussian Splatting (3DGS) from Gaussian Splatting SLAM (MonoGS) for precise point cloud and visual odometry estimations. It runs in monocular mode (tracking only, no depth) or RGB-D mode using real depth from a dataset, a depth camera, or a ROS 2 depth topic. It can also make use of a calibrated camera's intrinsics from a `CameraInfo` topic when running live. The system outputs high-quality point clouds and visual odometry data, making RGBD-3DGS-SLAM a versatile tool for a wide range of applications in robotics and computer vision.

<div align="center">
    <img src="assets/real_time_ROS.png" alt="Real-Time MonoGS ROS 2" width="800"/>
    <p>Real-Time MonoGS with ROS 2</p>
</div>

## 🏁 Dependencies

Clone the repo and the submodules using 
```
git clone https://github.com/jagennath-hari/RGBD-3DGS-SLAM --recursive
```

Install the packages using
```
cd RGBD-3DGS-SLAM && chmod +x install.sh && source ./install.sh
```

Or build from source using these libraries.

1) PyTorch ([Official Link](https://pytorch.org/)).
2) MonoGS ([Official Link](https://github.com/muskie82/MonoGS)).
3) RoboStack ROS 2 Humble ([Offical Link](https://robostack.github.io/GettingStarted.html)).

There is also enviroment.yml file, you can install or use as a reference using
```
conda env create -f environment.yml
```

## Downloading TUM dataset
```
cd MonoGS && bash scripts/download_tum.sh
```

*Tested on Ubuntu 22.04 and PyTorch 2.3.*

## ⌛️ Running SLAM on TUM
```cd MonoGS``` Move to this directory.
### TUM office
You can run the system on the TUM dataset using the same method from the [original repository](https://github.com/muskie82/MonoGS).

#### Monocular mode
```
python slam.py --config configs/mono/tum/fr3_office.yaml
```

#### RGB-D mode using the ground truth depth
It can be executed the same way as the [original repository](https://github.com/muskie82/MonoGS), using the ground truth depth maps shipped with the TUM dataset.

```
python slam.py --config configs/rgbd/tum/fr3_office.yaml
```

<div align="center">
    <img src="assets/ground_truth_depth.png" width="500" alt="Ground truth Depth Map from TUM dataset" />
    <p>Ground truth Depth Map from TUM dataset</p>
</div>

<div align="center">
    <img src="assets/original_MonoGS_result.png" width="500" alt="MonoGS Result" />
    <p>MonoGS Result</p>
</div>

<div align="center">
    <img src="assets/monoGS_rviz.png" alt="monoGS_rviz" width="800"/>
    <p>Final Cloud in RVIZ 2</p>
</div>

##### Cloud Viewer
An online [Guassian Viewer](https://antimatter15.com/splat/) can be used to view the cloud in the `result` directory.

<div align="center">
    <img src="assets/MonoGS_TUM_orginal_cloud.gif" width="500" alt="MonoGS Cloud" />
    <p>MonoGS Cloud</p>
</div>


## 📈 Running Real-Time using ROS 2
To run using any camera you can leverage ROS 2 publisher-subscriber (DDS) protocol. A new config file `MonoGS/configs/live/ROS.yaml` will allow you to use ROS 2.

You can change the topic names in the config file. An example given below.

```
ROS_topics:
  camera_topic: '/zed2i/zed_node/rgb/image_rect_color'
  camera_info_topic: '/zed2i/zed_node/rgb/camera_info'
  depth_topic: '/zed2i/zed_node/depth/depth_registered'
  depth_scale: 1
```

The `camera topic` is mandatory, but `camera_info_topic` and `depth_topic` are optional.

The other combinations are
1) An uncalibrated camera with Depth Maps.
```
ROS_topics:
  camera_topic: '/zed2i/zed_node/rgb/image_rect_color'
  camera_info_topic: 'None'
  depth_topic: '/zed2i/zed_node/depth/depth_registered'
  depth_scale: 1
```
2) A calibrated camera without Depth Maps.
```
ROS_topics:
  camera_topic: '/zed2i/zed_node/rgb/image_rect_color'
  camera_info_topic: '/zed2i/zed_node/rgb/camera_info'
  depth_topic: 'None'
  depth_scale: 1
```
3) An uncalibrated camera without Depth Maps.
```
ROS_topics:
  camera_topic: '/zed2i/zed_node/rgb/image_rect_color'
  camera_info_topic: 'None'
  depth_topic: 'None'
  depth_scale: 1
```
Whenever `camera_info_topic` is set to `'None'`, the camera intrinsics must instead be provided directly in the config under `Dataset.Calibration` (`fx`, `fy`, `cx`, `cy`, distortion coefficients, `width`, `height`); the system has no way to infer them otherwise.

To execute the SLAM system
Move to MonoGS directory if not already ```cd MonoGS```.

To start the system

```
python slam.py --config configs/live/ROS.yaml
```

### ⚠️ Note
Depth Maps can be of different scales, make sure to set the depth scale in the ROS topics infos.

It is advised to use a calibrated camera (a `camera_info_topic`) and provide Depth Maps if available, since there is no fallback estimation for either.

### Real-Time ROS 2 output Viewer and in RVIZ 2
<div align="center">
    <img src="assets/real_time_ROS.png" alt="SLAM" width="800"/>
    <p>MonoGS with ROS 2</p>
</div>

#### ROS 2 message outputs
During operation the system will output two topics when a new keyframe is created:
1) /monoGS/cloud (sensor_msgs/PointCloud2)
2) /monoGS/trajectory (nav_msgs/Path)

## 📖 Citation
If you found this code/work to be useful in your own research, please considering citing the following:
```bibtex
@inproceedings{Matsuki:Murai:etal:CVPR2024,
  title={{G}aussian {S}platting {SLAM}},
  author={Hidenobu Matsuki and Riku Murai and Paul H. J. Kelly and Andrew J. Davison},
  booktitle={Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition},
  year={2024}
}
```

## 🪪 License
This software is released under BSD-3-Clause license. You can view a license summary [here](LICENSE). [MonoGS](https://github.com/muskie82/MonoGS) has its own license.

## 🙏 Acknowledgement
This work incorporates many open-source codes.
- [Gaussian Splatting SLAM](https://github.com/muskie82/MonoGS)
- [3D Gaussian Splatting](https://github.com/graphdeco-inria/gaussian-splatting)
- [Differential Gaussian Rasterization
](https://github.com/graphdeco-inria/diff-gaussian-rasterization)
- [SIBR_viewers](https://gitlab.inria.fr/sibr/sibr_core)
- [Tiny Gaussian Splatting Viewer](https://github.com/limacv/GaussianSplattingViewer)
- [Open3D](https://github.com/isl-org/Open3D)
- [Point-SLAM](https://github.com/eriksandstroem/Point-SLAM)
- [splat](https://github.com/antimatter15/splat)
