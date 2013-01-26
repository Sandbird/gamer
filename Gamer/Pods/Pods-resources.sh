#!/bin/sh

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
      echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "rsync -rp ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -rp "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *)
      echo "cp -R ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      cp -R "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      ;;
  esac
}
install_resource 'Kal/Kal/kal_grid_background.png'
install_resource 'Kal/Kal/kal_grid_shadow.png'
install_resource 'Kal/Kal/kal_header_text_fill.png'
install_resource 'Kal/Kal/kal_left_arrow.png'
install_resource 'Kal/Kal/kal_marker.png'
install_resource 'Kal/Kal/kal_marker_dim.png'
install_resource 'Kal/Kal/kal_marker_selected.png'
install_resource 'Kal/Kal/kal_marker_today.png'
install_resource 'Kal/Kal/kal_right_arrow.png'
install_resource 'Kal/Kal/kal_tile.png'
install_resource 'Kal/Kal/kal_tile_dim_text_fill.png'
install_resource 'Kal/Kal/kal_tile_selected.png'
install_resource 'Kal/Kal/kal_tile_text_fill.png'
install_resource 'Kal/Kal/kal_tile_today.png'
install_resource 'Kal/Kal/kal_tile_today_selected.png'
